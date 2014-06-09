# Mission Assignment DSL
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'missions/dsl/helpers'

module Missions
module DSL

# Mission Assignment
module Assignment
  include Helpers

  # Invoke the specified lookup proc and store the result in the mission data
  def self.store(id, lookup)
    proc { |mission|
      mission.mission_data[id] = lookup.call(mission)
      update_mission mission
    }
  end

  # Create a ship with the specified params
  #
  # TODO rename or expand to also create stations
  def self.create_entity(id, entity_params={})
    proc { |mission|
      # create new entity using specified params
      entity_params[:id] = Motel.gen_uuid if entity_params[:id].nil?
      entity = Manufactured::Ship.new entity_params
      mission.mission_data[id] = entity

      # TODO only if ship does not exist
      node.invoke('manufactured::create_entity', entity)
      update_mission mission
    }
  end

  # Create an asteroid w/ the specified params
  def self.create_asteroid(id, entity_params={})
    proc { |mission|
      entity_params[:id] = Motel.gen_uuid if entity_params[:id].nil?
      entity_params[:name] = entity_params[:id] if entity_params[:name].nil?
      ast = Cosmos::Entities::Asteroid.new entity_params
      mission.mission_data[id] = ast
      node.invoke 'cosmos::create_entity', ast
      update_mission mission
    }
  end

  # Associate a resource w/ an existing cosmos entity
  def self.create_resource(entity_id, rs_params={})
    proc { |mission|
      entity = mission.mission_data[entity_id]
      rs  = Cosmos::Resource.new({:id => Motel.gen_uuid,
                                  :entity => entity}.merge(rs_params))
      node.notify 'cosmos::set_resource', rs
    }
  end

  # Add a resource to the specified manufactured entity
  def self.add_resource(entity_id, rs_params={})
    proc { |mission|
      entity = mission.mission_data[entity_id]
      rs  = Cosmos::Resource.new({:id => Motel.gen_uuid,
                                  :entity => entity}.merge(rs_params))
      node.notify 'manufactured::add_resource', entity.id, rs
    }
  end

  # Subcribe node to event on specified entity(ies) invoking
  # handler(s) when event occurs
  def self.subscribe_to_entity_event(entities, evnt, handlers)
    proc { |mission|
      entities = [entities] unless entities.is_a?(Array)
      handlers = [handlers] unless handlers.is_a?(Array)

      entities.collect! { |entity|
        # this could be an array
        entity.is_a?(String) ? mission.mission_data[entity] : entity
      }.flatten!

      entities.each { |entity|
        # add handler to registry
        eid     = Missions::Events::Manufactured.gen_id(entity.id, evnt)

        # TODO mark event handler as persistant &
        # remove handlers on mission completion/failure
        handler = Omega::Server::EventHandler.new(:event_id => eid) { |e|
                    handlers.each { |h| h.call(mission, e) }
                  }
        registry << handler

        # subscribe to server side events
        node.invoke('manufactured::subscribe_to', entity.id, evnt)
      }
    }
  end

  # Subscribe node to subsystem event invoking handler(s)
  # when it occurs
  #
  # TODO other subsystem events
  def self.subscribe_to_subsystem_event(evnt, handlers)
    proc { |mission|
      handlers = [handlers] unless handlers.is_a?(Array)

      handler = Missions::EventHandlers::ManufacturedEventHandler.
                  new(:manu_event_type => evnt, :persist => true){ |e|
                  handlers.each { |h| h.call(mission, e) }
                }
      registry << handler

      node.invoke('manufactured::subscribe_to', evnt)
    }
  end

  # Subscribe node to entity or subsystem event
  def self.subscribe_to(*args)
    proc { |mission|
      args.length > 2 ? subscribe_to_entity_event(*args).call(mission) :
                        subscribe_to_subsystem_event(*args).call(mission)
    }
  end

  # Add an event to the registry for mission timeout/expiration
  def self.schedule_expiration_events
    proc { |mission|
      timestamp = mission.assigned_time + mission.timeout
      expired   = Missions::Events::Expired.new :mission   => mission,
                                                :timestamp => timestamp
      failed    = Missions::Events::Failed.new  :mission   => mission,
                                                :timestamp => timestamp
      registry << expired
      registry << failed
    }
  end

end # module Assignment
end # module DSL
end # module Missions
