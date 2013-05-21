# cosmos::create_entity rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

create_entity = proc { |entity, parent_name|
  Users::Registry.require_privilege(:privilege => 'create', :entity => 'cosmos_entities',
                                    :session   => @headers['session_id'])

  valid_types = Cosmos::Registry.instance.entity_types
  raise ArgumentError, "Invalid #{entity.class} entity specified, must be one of #{valid_types.inspect}" unless valid_types.include?(entity.class)

  parent_type = entity.class.parent_type

  rparent = Cosmos::Registry.instance.find_entity(:type => parent_type, :name => parent_name)
  raise Omega::DataNotFound, "parent entity of type #{parent_type} with name #{parent_name} not found" if rparent.nil?

  # XXX ugly but allows us to lookup entities by name for the time being
  #   at some point change / remove this
  unless entity.is_a?(Cosmos::JumpGate)
    rentity = Cosmos::Registry.instance.find_entity(:name => entity.name)
    raise ArgumentError, "#{entity.class} name #{entity.name} already taken" unless rentity.nil?
  end

  Cosmos::Registry.instance.safely_run {
    # setting location must occur before entity is added to parent
    # entity.location.entity = entity
    entity.location.restrict_view = false
    entity.location = @@local_node.invoke_request('motel::create_location', entity.location)
    entity.location.parent = rparent.location
    # TODO add all of entities children to location tracker
  }


  # TODO rparent.can_add?(entity)
  Cosmos::Registry.instance.safely_run {
    entity.parent= rparent
    rparent.add_child entity
  }

  entity
}

def dispatch_create_entity(dispatcher)
  dispatcher.handle 'cosmos::create_entity', &create_entity
end
