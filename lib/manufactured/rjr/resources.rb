# manufactured::add_resource, manufactured::transfer_resource
# rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# adds the specified resource to the specified entity,
# XXX would rather not have but needed by other subsystems
manufactured_add_resource = proc { |entity_id, resource_id, quantity|
  # require local transport
  raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE

  # require modify manufactured_resources
  # also require modify on the entity ?
  Users::Registry.require_privilege(:privilege => 'modify', :entity => 'manufactured_resources',
                                    :session   => @headers['session_id'])

  entity = Manufactured::Registry.instance.find(:id => entity_id).first
  raise Omega::DataNotFound, "manufactured entity specified by #{entity_id} not found"  if entity.nil?

  raise ArgumentError, "quantity must be an int / float > 0" if (!quantity.is_a?(Integer) && !quantity.is_a?(Float)) || quantity <= 0

  # TODO validate resource_id

  Manufactured::Registry.instance.safely_run {
    entity.add_resource resource_id, quantity
  }

  entity
}

manufactured_transfer_resource = proc { |from_entity_id, to_entity_id, resource_id, quantity|
  raise ArgumentError, "quantity must be an int / float > 0" if (!quantity.is_a?(Integer) && !quantity.is_a?(Float)) || quantity <= 0

  from_entity = Manufactured::Registry.instance.find(:id => from_entity_id).first
  to_entity   = Manufactured::Registry.instance.find(:id => to_entity_id).first
  raise Omega::DataNotFound, "entity specified by #{from_entity_id} not found" if from_entity.nil?
  raise Omega::DataNotFound, "entity specified by #{to_entity_id} not found"   if to_entity.nil?

  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{from_entity.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])
  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{to_entity.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])

  # update from & to entitys' location
  Manufactured::Registry.instance.safely_run {
    from_entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', from_entity.location.id))
    to_entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', to_entity.location.id))

    raise Omega::OperationError, "source entity cannot transfer resource" unless from_entity.can_transfer?(to_entity, resource_id, quantity)
    raise Omega::OperationError, "destination entity cannot accept resource" unless to_entity.can_accept?(resource_id, quantity)
  }

  entities = Manufactured::Registry.instance.transfer_resource(from_entity, to_entity, resource_id, quantity)
  raise Omega::OperationError, "problem transferring resources from #{from_entity} to #{to_entity}" if entities.nil?
  entities
}

def dispatch_resources(dispatcher)
  dispatcher.handle 'manufactured::add_resource',
                      &manufactured_add_resource
  dispatcher.handle 'manufactured::transfer_resource',
                      &manufactured_transfer_resource
end
