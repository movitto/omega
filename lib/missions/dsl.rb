# Missions Server DSL
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'json'
require 'omega/common'

module Missions

# Various callbacks and utility methods for use in mission creation.
#
# The DSL methods themselves just return procedures to be registered
# with the various mission callback to be executed at various stages
# in the mission lifecycles (assignment, victory, expiration, etc)

require 'users/attributes/stats'

module DSL

# Client DSL
module Client

# Client side dsl proxy
#
# Mechanism to allow clients to specify dsl methods to be used in
# server side operations.
#
# Since these dsl methods are not serializable the client sends
# instances of this proxy in place which will be resolved on the server side
class Proxy
  # Proxy dsl methods invoked directly on the class
  def self.method_missing(method_id, *args)
    DSL.constants.each { |c|
      dc = DSL.const_get(c)
      # XXX different dsl categories cannot define methods
      # with the same name, would be nice to resolve this
      if(dc.methods.include?(method_id))
        return Proxy.new :dsl_category => c.to_s,
                         :dsl_method   => method_id.to_s,
                         :params       => args
      end
    }
    nil
  end

  attr_accessor :dsl_category
  attr_accessor :dsl_method
  attr_accessor :params

  def initialize(args={})
    attr_from_args args, :dsl_category => nil,
                         :dsl_method   => nil,
                         :params       =>  []
  end

  def self.resolve(args={})
    mission = args[:mission]
    event_handler = args[:event_handler]

    Mission::CALLBACKS.each { |cb|
      dsl_category = self.dsl_category_for(cb)

      cbs = mission.send(cb)
      cbs.each_index { |i|
        if cbs[i].is_a?(Proxy)
          cbs[i] = cbs[i].resolve

        elsif cbs[i].is_a?(String)
          proxy = Proxy.new :dsl_category => dsl_category.to_s,
                            :dsl_method   => cbs[i]
          cbs[i] = proxy.resolve

        elsif cbs[i].is_a?(Array)
          dsl_method = cbs[i].shift
          proxy = Proxy.new :dsl_category => dsl_category.to_s,
                            :dsl_method   => dsl_method,
                            :params       => cbs[i]
          cbs[i] = proxy.resolve
        end
      }
    } if mission

    event_handler.missions_callbacks.each_index { |cbi|
      cb = event_handler.missions_callbacks[cbi]
      event_handler.missions_callbacks[cbi] = cb.resolve if cb.is_a?(Proxy)
    } if event_handler
  end

  def self.dsl_categories
    @dsl_categories ||= {:requirements         => Missions::DSL::Requirements,
                         :assignment_callbacks => Missions::DSL::Assignment,
                         :victory_conditions   => Missions::DSL::Query,
                         :victory_callbacks    => Missions::DSL::Resolution,
                         :failure_callbacks    => Missions::DSL::Resolution}
  end

  def self.dsl_category_for(cb_type)
    dsl_categories[cb_type]
  end

  def resolve
    short_category = dsl_category.to_s.demodulize

    return unless Missions::DSL.constants.collect { |c| c.to_s }.include?(short_category)
    dcategory = Missions::DSL.const_get(short_category.intern)

    return unless dcategory.methods.collect { |m| m.to_s }.include?(dsl_method.to_s)
    dmethod = dcategory.method(dsl_method)

    # scan through params, call resolve on proxies
    params.each_index { |i|
      param     = params[i]
      params[i] = param.resolve if param.is_a?(Proxy)
    }

    dmethod.call *params
  end

  def to_json(*a)
     {
       'json_class'     => self.class.name,
       'data'           =>
         {:dsl_category => dsl_category,
          :dsl_method   => dsl_method,
          :params       => params}
     }.to_json(*a)
  end

  def self.json_create(o)
    new(o['data'])
  end
end # class Proxy

# map top level missions dsl modules into client namespace
Requirements = Proxy
Assignment   = Proxy
Event        = Proxy
EventHandler = Proxy
Query        = Proxy
Resolution   = Proxy

end # module Client

module Helpers
  # Internal helper method to update registry mission
  def update_mission(mission)
    Missions::RJR.registry.update(mission) { |m| m.id == mission.id }
  end

  # Internal helper to provide access to registry
  def registry
    Missions::RJR.registry
  end

  # Internal helper to provide access to node
  def node
    Missions::RJR.node
  end
end

# Mission Requirements
module Requirements
  extend Helpers

  # Ensure both mission owner and user its being assigned to have at least one
  # ship docked at a common station
  def self.shared_station
    proc { |mission, assigning_to|
      # ensure users have a ship docked at a common station
      created_by = mission.creator
      centities  = node.invoke('manufactured::get_entities',
                               'of_type', 'Manufactured::Ship',
                               'owned_by', created_by.id)
      cstats     = centities.collect { |s| s.docked_at_id }.compact

      aentities  = node.invoke('manufactured::get_entities',
                               'of_type', 'Manufactured::Ship',
                               'owned_by', assigning_to.id)
      astats     = aentities.collect { |s| s.docked_at_id }.compact

      !(cstats & astats).empty?
    }
  end

  # Ensure user mission is being assigned to has a ship at the specified station
  def self.docked_at(station)
    proc { |mission, assigning_to|
      # ensure user has ship docked at specified station
      aentities  = node.invoke('manufactured::get_entities',
                               'of_type', 'Manufactured::Ship',
                               'owned_by', assigning_to.id)
      astats     = aentities.collect { |s| s.docked_at_id }.compact

      astats.include?(station.id)
    }
  end
end

# Mission Assignment
module Assignment
  extend Helpers

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
  def self.schedule_expiration_event
    proc { |mission|
      registry  = Missions::RJR.registry
      timestamp = mission.assigned_time + mission.timeout
      expired   = Missions::Events::Expired.new :mission   => mission,
                                                :timestamp => timestamp,
                                                :registry  => registry
      registry << expired
      # TODO also emit a 'failed' event
    }
  end
end

# Mission related events
module Event
  extend Helpers

  def self.resource_collected
    proc { |mission, evnt|
      rs = evnt.manufactured_event_args[2].material_id
      q  = evnt.manufactured_event_args[3]
      mission.mission_data['resources']     ||= {}
      mission.mission_data['resources'][rs] ||= 0
      mission.mission_data['resources'][rs]  += q
      update_mission mission

      if Query.check_mining_quantity.call(mission)
        Event.create_victory_event.call(mission, evnt)
      end
    }
  end

  def self.transferred_out
    proc { |mission, evnt|
      dst = evnt.manufactured_event_args[2]
      rs  = evnt.manufactured_event_args[3]
      mission.mission_data['last_transfer'] =
        { 'dst' => dst, 'rs' => rs.material_id, 'q' => rs.quantity }
      update_mission mission

      if Query.check_transfer.call(mission)
        Event.create_victory_event.call(mission, evnt)
      end
    }
  end

  def self.entity_destroyed
    proc { |mission, evnt|
      mission.mission_data['destroyed'] ||= []
      mission.mission_data['destroyed'] << evnt
      update_mission mission
    }
  end

  def self.collected_loot
    proc { |mission, evnt|
      loot = evnt.manufactured_event_args[2]
      mission.mission_data['loot'] ||= []
      mission.mission_data['loot'] << loot
      update_mission mission

      if Query.check_loot.call(mission)
        Event.create_victory_event.call(mission, evnt)
      end
    }
  end

  def self.check_victory_conditions
    proc { |mission, evnt|
      create_victory_event.call(mission, evnt) if mission.completed?
    }
  end

  def self.create_victory_event
    proc { |mission, evnt|
      # TODO ensure not failed, check victory conditions ?
      victory  = Missions::Events::Victory.new :mission  => mission,
                                               :registry => registry
      registry << victory
    }
  end

  # TODO 'continuation' event to create more entities or whatever else
end

# Mission related event handlers
# XXX rename these methods
module EventHandler
  extend Helpers

  def self.on_event_create_entity(args={})
    event       = args[:event]       || args['event']
    entity_type = args[:entity_type] || args['entity_type']
    id          = args[:id]          || args['id']
    case event
    when 'registered_user' then
      proc { |event|
        args[:id]      = id || Motel.gen_uuid
        args[:user_id] = event.users_event_args[1].id
        entity = entity_type == 'Manufactured::Ship' ?
            Manufactured::Ship.new(args) :
            Manufactured::Station.new(args)

        # TODO only if ship does not exist
        node.invoke('manufactured::create_entity', entity)
      }

    else
      nil

    end
  end

  def self.on_event_add_role(args={})
    event = args[:event] || args['event']
    role  = args[:role]  || args['role']
    case event
    when 'registered_user' then
      proc { |event|
        user_id = event.users_event_args[1].id
        node.invoke('users::add_role', user_id, role)
      }
    else
      nil
    end
  end
end

# Mission Queries
module Query
  extend Helpers

  # Return bool indicating if the ships hp == 0 (eg ship is destroyed)
  def self.check_entity_hp(id)
    proc { |mission|
      # check if entity is destroyed
      entity = mission.mission_data[id]
      entity = node.invoke('manufactured::get_entity', entity.id)
      entity.nil? || entity.hp == 0
    }
  end

  # Return bool indicating if user has acquired target mining quantity
  def self.check_mining_quantity
    proc { |mission|
      q = mission.mission_data['resources'][mission.mission_data['target']]
      mission.mission_data['quantity'] <= q
    }
  end

  # Return bool indicating if user has transfered the target resource
  def self.check_transfer
    proc { |mission|
      mission.mission_data['last_transfer'] &&

      mission.mission_data['check_transfer']['dst'].id ==
      mission.mission_data['last_transfer']['dst'].id  &&

      mission.mission_data['check_transfer']['rs'] ==
      mission.mission_data['last_transfer']['rs']  &&

      mission.mission_data['check_transfer']['q'] >=
      mission.mission_data['last_transfer']['q']
    }
  end

  # Return boolean indicating if user has collected the target loot
  def self.check_loot
    proc { |mission|
      !mission.mission_data['loot'].nil?
      !mission.mission_data['loot'].find { |rs|
        rs.material_id == mission.mission_data['check_loot']['res'] &&
        rs.quantity    >= mission.mission_data['check_loot']['q']
      }.nil?
    }
  end

  # Return ships the user owned that matches the speicifed properties filter
  def self.user_ships(filter={})
    proc { |mission|
      node.invoke('manufactured::get_entity',
                  'of_type', 'Manufactured::Ship',
                  'owned_by', mission.assigned_to_id).
        select { |s| filter.keys.all? { |k| s.send(k).to_s == filter[k].to_s }}
    }
  end

  # Return first ship returned by user_ships
  def self.user_ship(filter={})
    proc { |mission|
      user_ships(filter).call(mission).first
    }
  end

  # Return bool indicating if all user entities have been destroyed
  def self.all_user_entities_destroyed(user_id)
    proc { |mission|
      entities = node.invoke('manufactured::get_entity', 'owned_by', user_id)
      entities.none? { |e| e.alive? }
    }
  end
end

# Mission Resolution
module Resolution
  extend Helpers

  # Add resource to a user owned entity
  def self.add_reward(rs)
    proc { |mission|
      # TODO better way to get user ship than this
      # TODO try other ships if add_resource fails
      entity = Query.user_ships.call(mission).first

      # add resources to player's cargo
      rs.id = Motel.gen_uuid
      rs.entity = entity
      node.invoke('manufactured::add_resource', entity.id, rs)
    }
  end

  # Updates mission-related user attributes
  def self.update_user_attributes
    proc { |mission|
      # update user attributes
      atr = mission.victorious ? Users::Attributes::MissionsCompleted.id :
                                 Users::Attributes::MissionsFailed.id
      node.invoke('users::update_attribute',
                                 mission.assigned_to_id,
                                 atr, 1)
    }
  end

  # Cleanup all events related to the mission
  def self.cleanup_events(id, *evnts)
    proc { |mission|
      entities = mission.mission_data[id]
      entities = [entities] unless entities.is_a?(Array)

      entities.each { |entity|
        # remove callbacks
        node.invoke('manufactured::remove_callbacks', entity.id)

        # remove event handlers
        evnts.each { |evnt|
          eid = Missions::Events::Manufactured.gen_id(entity.id, evnt)
          registry.cleanup_event(eid)
        }

        # remove expiration event
        eid = "mission-#{mission.id}-expired"
        registry.cleanup_event(eid)
      }
    }
  end

  # Recycle mission, eg clone it w/ a new id, clear assignment,
  # and add it to the registry
  def self.recycle_mission
    proc { |mission|
      # create a new mission based on the specified one
      new_mission = mission.clone :id => Motel.gen_uuid
      new_mission.clear_assignment!
      node.invoke('missions::create_mission', new_mission)
    }
  end
end

end # Module DSL
end # Module Missions
