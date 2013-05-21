# manufactured::start_mining rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

manufactured_start_mining = proc { |ship_id, entity_id, resource_id|
  ship = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first
  # TODO how/where to incorporate resource scanning distance & capabilities into this
  resource_sources = @@local_node.invoke_request('cosmos::get_resource_sources', entity_id)
  resource_source  = resource_sources.find { |rs| rs.resource.id == resource_id }
  
  raise Omega::DataNotFound, "ship specified by #{ship_id} not found" if ship.nil?
  raise Omega::DataNotFound, "resource_source specified by #{entity_id}/#{resource_id} not found" if resource_source.nil?
  
  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])
  
  
  before_mining_cycle = lambda { |cmd|
    # update ship's location
    cmd.ship.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.ship.location.id))
  
    # XXX don't like having to do this but need to load resource source's entity's location parent explicity
    cmd.resource_source.entity.location.parent = @@local_node.invoke_request('motel::get_location', 'with_id', cmd.resource_source.entity.location.parent_id)
  
    # raise error if miner cannot mine resource
    raise Omega::OperationError, "#{cmd.ship} cannot mine #{cmd.resource_source}" unless ship.can_mine?(cmd.resource_source)
  
    # remove existing collected/depleted callbacks on local node
    cmd.ship.notification_callbacks.reject!{ |nc| nc.endpoint_id == @@local_node.message_headers['source_node'] &&
                                                  [:mining_stopped, :resource_collected].include?(nc.type) }
  
    # Resource_source is a copy of actual resource_source
    # stored in cosmos registry, wire up callbacks to update original.
    # Also update user attributes
    collected_callback =
      Callback.new(:resource_collected, :endpoint => @@local_node.message_headers['source_node']){ |*args|
        sh = args[1]
        rs = args[2]
        @@local_node.invoke_request('cosmos::set_resource', rs.entity.name, rs.resource, rs.quantity)
  
        @@local_node.invoke_request('users::update_attribute', sh.user_id,
                                    Users::Attributes::ResourcesCollected.id, rs.quantity)
      }
    depleted_callback =
      Callback.new(:mining_stopped, :endpoint => @@local_node.message_headers['source_node']){ |*args|
        ship = args[2]
        ship.notification_callbacks.delete collected_callback
        ship.notification_callbacks.delete depleted_callback
      }
    cmd.ship.notification_callbacks << collected_callback
    cmd.ship.notification_callbacks << depleted_callback
  }
  
  # update location before mining
  before_mining = lambda { |cmd|
    cmd.ship.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.ship.location.id))
  }
  
  Manufactured::Registry.instance.schedule_mining :ship => ship,
                                                  :resource_source => resource_source,
                                                  :before => before_mining,
                                                  :first  => before_mining_cycle
  ship
}

def dispatch_mining(dispatcher)
  dispatcher.handle 'manufactured::start_mining',
                      &manufactured_start_mining
  # dispatcher.handle('manufactured::stop_mining', 'TODO')
end
