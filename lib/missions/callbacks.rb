# Mission Callbacks definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Missions

# Many various callbacks and utility methods for use in mission creation
module Callbacks
module Requirement
  def self.shared_station
    proc { |mission, assigning_to, node|
      # ensure users have a ship docked at a common station
      created_by = mission.creator
      centities  = node.invoke_request('manufactured::get_entities', 'of_type', 'Manufactured::Ship', 'owned_by', created_by.id)
      cstats     = centities.collect { |s| s.docked_at.nil? ? nil : s.docked_at.id }.compact

      aentities  = node.invoke_request('manufactured::get_entities', 'of_type', 'Manufactured::Ship', 'owned_by', assigning_to.id)
      astats     = aentities.collect { |s| s.docked_at.nil? ? nil : s.docked_at.id }.compact

      !(cstats & astats).empty?
    }
  end

  def self.docked_at(station)
    proc { |mission, assigning_to, node|
      # ensure user has ship docked at specified station
      aentities  = node.invoke_request('manufactured::get_entities', 'of_type', 'Manufactured::Ship', 'owned_by', assigning_to.id)
      astats     = aentities.collect { |s| s.docked_at.nil? ? nil : s.docked_at.id }.compact

      astats.include?(station.id)
    }
  end
end

module Assignment
  def self.create_entity(id, entity_params={})
    proc { |mission, node|
      # create new entity using specified params
      entity = Manufactured::Ship.new entity_params
      mission.mission_data[id] = entity

      # TODO only if ship does not exist
      node.invoke_request('manufactured::create_entity', entity)
    }
  end

  def self.create_asteroid(id, entity_params={})
    proc { |mission, node|
      ast = Cosmos::Asteroid.new entity_params
      mission.mission_data[id] = ast
      node.invoke_request 'cosmos::create_entity', ast, entity_params[:solar_system]
    }
  end

  def self.create_resource(entity_id, rstype, rsname, quantity)
    proc { |mission, node|
      entity = mission.mission_data[entity_id]
      rs  = Cosmos::Resource.new(:type => rstype, :name => rsname)
      node.send_notification 'cosmos::set_resource', entity.name, rs, quantity
    }
  end

  def self.add_resource(entity_id, rstype, rsname, quantity)
    proc { |mission, node|
      entity = mission.mission_data[entity_id]
      rs  = Cosmos::Resource.new(:type => rstype, :name => rsname)
      node.send_notification 'manufactured::add_resource', entity.id, rs.id, quantity
    }
  end

  def self.subscribe_to(entities, evnt, handlers)
    proc { |mission, node|
      entities = mission.mission_data[entities] if entities.is_a?(String)
      entities = [entities] unless entities.is_a?(Array)
      handlers = [handlers] unless handlers.is_a?(Array)

      entities.each { |entity|
        entity = mission.mission_data[entity] if entity.is_a?(String)

        Missions::Registry.instance.unsafely_run { # XXX need to unlock registry
          # handle entity event
          Missions::Registry.instance.handle_event(entity.id + '_' + evnt) { |e|
            handlers.each { |handler|
              handler.call(mission, node, e)
            }
          }
        }

        # subscribe to server side events
        node.invoke_request('manufactured::subscribe_to', entity.id, evnt)
      }
    }
  end

  def self.schedule_expiration_event
    proc { |mission, node|
      id = "mission-#{mission.id}-expired"
      # add event for mission expiration
      expired = Missions::Event.new :id => id,
                  :timestamp => mission.assigned_time + mission.timeout,
                  :callbacks => [proc{ |e|
                     # TODO ensure not victorious, move this to new event class, lock registry
                     mission.failed! # if mission.expired?
                   }]

      Missions::Registry.instance.unsafely_run { # XXX need to unlock registry
        Missions::Registry.instance.create expired
      }
    }
  end
end

module Event
  def self.resource_collected
    proc { |mission, node, evnt|
      rs = evnt.manufactured_event_args[2].resource.id
      q  = event.manufactured_event_args[3]
      mission.mission_data[:resources][rs] += q

      if Query.check_mining_quantity.call(mission, node)
        Event.create_victory_event.call(mission, node, evnt)
      end
    }
  end

  def self.transferred_out
    proc { |mission, node, evnt|
      dst = evnt[2]
      rs  = evnt[3]
      q   = evnt[4]
      mission.mission_data[:last_transfer] = { :dst => dst, :rs => rs, :q => q }

      if Query.check_transfer.call(mission, node)
        Event.create_victory_event.call(mission, node, evnt)
      end
    }
  end

  def self.entity_destroyed
    proc { |mission, node, evnt|
      entity 
      mission.mission_data[:destroyed] << evnt
    }
  end

  def self.collected_loot
    proc { |mission, node, evnt|
      loot = evnt.manufactured_event_arg[2]
      mission.mission_data[:loot] << loot

      if Query.check_loot.call(mission, node)
        Event.create_victory_event.call(mission, node, evnt)
      end
    }
  end

  def self.check_victory_conditions
    proc { |mission, node, evnt|
      # TODO
    }
  end

  def self.create_victory_event
    proc { |mission, node, evnt|
      # TODO ensure not failed, check victory conditions, lock registry
      mission.victory! # if mission.completed?

      id = "mission-#{mission.id}-succeeded"
      victory = Missions::Event.new :id => id, :timestamp => Time.now
      Missions::Registry.instance.create victory
    }
  end

  # TODO 'continuation' event to create more entities or whatever else
end

module Query
  def self.check_entity_hp(id)
    proc { |mission, node|
      # check if entity is destroyed
      entity = mission.mission_data[id]
      entity = node.invoke_request('manufactured::get_entity', entity.id)
      entity.nil? # or also search graveyard and verify hp == 0
    }
  end

  def self.check_mining_quantity
    proc { |mission, node|
      q = mission.mission_data[:resources][mission.mission_data[:target]]
      mission.mission_data[:quantity] == q
    }
  end

  def self.check_transfer
    proc { |mission, node|
      missions.mission_data[:last_transfer] &&
      mission.mission_data[:check_transfer][:dst] == mission.mission_data[:last_transfer][:dst] &&
      mission.mission_data[:check_transfer][:rs]  == mission.mission_data[:last_transfer][:rs]  &&
      mission.mission_data[:check_transfer][:q]   == mission.mission_data[:last_transfer][:q]
    }
  end

  def self.check_transfer
    proc { |mission, node|
      !missions.mission_data[:loot].find { |l|
        !l.resources.find { |rs,q|
          rs == missions.mission_data[:check_loot][:res] &&
           q == missions.mission_data[:check_loot][:q]
        }.nil?
      }.nil?
    }
  end

  def self.user_ships(&filter)
    proc { |mission, node|
      filter = proc { |i| true } unless filter
      node.
        invoke_request('manufactured::get_entity',
                       'of_type', 'Manufactured::Ship',
                       'owned_by', mission.assigned_to_id).
        select(&filter)
    }
  end

end

module Resolution
  def self.add_resource(rs, q)
    proc { |mission, node|
      # TODO better way to get user ship than this
      entity = Query.user_ships.call(mission, node).first

      # add resources to player's cargo
      node.invoke_request('manufactured::add_resource', entity.id, rs, q)
    }
  end

  def self.update_user_attributes
    proc { |mission, node|
      # update user attributes
      attr = mission.victorious ? Users::Attributes::MissionsCompleted.id :
                                     Users::Attributes::MissionsFailed.id
      node.invoke_request('users::update_attribute', mission.assigned_to_id,
                          attr, 1)
    }
  end

  def self.cleanup_events(id, *evnts)
    proc { |mission, node|
      entities = mission.mission_data[id]
      entities = [entities] unless entities.is_a?(Array)

      entities.each { |entity|
        node.invoke_request('manufactured::remove_callbacks', entity.id)
        evnts.each { |evnt|
          Missions::Registry.instance.remove_event_handler("#{entity.id}_#{evnt}")
        }
        Missions::Registry.instance.remove("mission-#{mission.id}-expired")
        # TODO flush other mission related events?
      }
    }
  end

  def self.recycle_mission
    proc { |mission, node|
      # create a new mission based on the specified one
      new_mission = mission.clone :id => Motel.gen_uuid
      new_mission.clear_assignment!
      node.invoke_request('missions::create_mission', new_mission)
    }
  end
end

end
end
