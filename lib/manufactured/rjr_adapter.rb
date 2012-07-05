# Manufactured rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'active_support/inflector'

module Manufactured

class RJRAdapter
  def self.user
    @@manufactured_user ||= Users::User.new(:id => 'manufactured',
                                            :password => 'changeme')
  end

  def self.init
    self.register_handlers(RJR::Dispatcher)
    #Manufactured::Registry.instance.init
    @@local_node = RJR::LocalNode.new :node_id => 'manufactured'
    @@local_node.message_headers['source_node'] = 'manufactured'
    @@local_node.invoke_request('users::create_entity', self.user)
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'view',   'cosmos_entities')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'modify', 'cosmos_entities')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'create', 'locations')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'view',   'users_entities')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'view',   'locations')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'modify', 'locations')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'create', 'manufactured_entities')

    session = @@local_node.invoke_request('users::login', self.user)
    @@local_node.message_headers['session_id'] = session.id
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('manufactured::create_entity'){ |entity|
      Users::Registry.require_privilege(:privilege => 'create', :entity => 'manufactured_entities',
                                        :session   => @headers['session_id'])

      valid_types = Manufactured::Registry.instance.entity_types
      raise ArgumentError, "Invalid #{entity.class} entity specified, must be one of #{valid_types.inspect}" unless valid_types.include?(entity.class)

      # swap out the parent w/ the one stored in the cosmos registry
      if !entity.is_a?(Manufactured::Fleet) && entity.parent
        parent = @@local_node.invoke_request('cosmos::get_entity', 'of_type', :solarsystem, 'with_name', entity.parent.name)
        raise Omega::DataNotFound, "parent system specified by #{entity.parent.name} not found" if parent.nil?
        entity.parent = parent
        # TODO parent.can_add?(entity)
      end

      rentity = Manufactured::Registry.instance.find(:id => entity.id).first
      raise ArgumentError, "#{entity.class} with id #{entity.id} already taken" unless rentity.nil?

      Manufactured::Registry.instance.create entity

      unless entity.is_a?(Manufactured::Fleet) || entity.location.nil?
        # needs to happen b4 create_location so motel sets up heirarchy correctly
        entity.location.parent_id = entity.parent.location.id if entity.parent

        # TODO: skip create_location if entity wasn't created in registry
        entity.location = @@local_node.invoke_request('motel::create_location', entity.location)

        # needs to happen after create_location as parent won't be sent in the result
        entity.location.parent    = entity.parent.location if entity.parent
      end

      entity
    }

    rjr_dispatcher.add_handler('manufactured::construct_entity') { |manufacturer_id, entity_type, *args|
      station = Manufactured::Registry.instance.find(:type => "Manufactured::Station", :id => manufacturer_id).first
      raise Omega::DataNotFound, "station specified by #{manufacturer_id} not found" if station.nil?

      Users::Registry.require_privilege(:privilege => 'create', :entity => 'manufactured_entities',
                                        :session   => @headers['session_id'])

      # simply convert remaining args into key /
      # value pairs to pass into construct
      # TODO verify station has construction capabilities for the specified args
      # TODO validate these in the context of the entities being created and the constructing station / system
      args = Hash[*args]

      # remove params which should not be set by the user
      ['solar_system','user_id',
       'resources', 'notifications',
       'docked_at', 'size'].each { |i| # set docked at to station?
        args.delete(i)
      }

      # auto-set additional params
      args[:entity_type] = entity_type
      args[:solar_system] = station.solar_system
      args[:user_id] = Users::Registry.current_user(:session => @headers['session_id']).id # TODO set permissions on entity?

      raise ArgumentError, "station specified by #{station} cannot construct entity specified by #{args}" unless station.can_construct?(args)

      # create the entity and return it
      entity = station.construct args
      raise ArgumentError, "could not construct #{entity_type} at #{station} with args #{args.inspect}" if entity.nil?
      @@local_node.invoke_request('manufactured::create_entity', entity)
      entity
    }

    rjr_dispatcher.add_handler(['manufactured::get_entity', 'manufactured::get_entities']){ |*args|
       filter = {}
       while qualifier = args.shift
         raise ArgumentError, "invalid qualifier #{qualifier}" unless ["of_type", "owned_by", "with_id", "with_location", "under"].include?(qualifier)
         val = args.shift
         raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
         qualifier = case qualifier
                       when "of_type"
                         :type
                       when "owned_by"
                         :user_id
                       when "with_id"
                         :id
                       when "with_location"
                         :location_id
                       when "under"
                         :parent_id
                     end
         filter[qualifier] = val
       end

       # if user specified id or location, return the first (and only) result on its own
       return_first = filter.has_key?(:id) || filter.has_key?(:location_id)

       # ensure user exists if user_id is specified
       if filter.has_key?(:user_id)
         user = @@local_node.invoke_request('users::get_entity', filter[:user_id])
         raise Omega::DataNotFound, "user specified by #{user_id} not found" if user.nil?
       end

       # ensure system exists if parent_id is specified
       if filter.has_key?(:parent_id)
         parent = @@local_node.invoke_request('cosmos::get_entity', 'of_type', :solarsystem, 'with_name', filter[:parent_id])
         raise Omega::DataNotFound, "parent system specified by #{parent_id} not found" if parent.nil?
       end

       entities = Manufactured::Registry.instance.find(filter)

       entities.reject! { |entity|
         !Users::Registry.check_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                   {:privilege => 'view', :entity => 'manufactured_entities'}],
                                          :session => @headers['session_id'])

       }

       entities.each { |entity|
         unless entity.is_a?(Manufactured::Fleet)
           entity.location = @@local_node.invoke_request('motel::get_location', entity.location.id)
         end
       }

       if return_first
         entities = entities.first
         raise Omega::DataNotFound, "manufactured entity specified by #{id} not found" if entities.nil?
       end

       entities
    }

    rjr_dispatcher.add_handler('manufactured::subscribe_to') { |entity_id, event|
      entity = Manufactured::Registry.instance.find(:id => entity_id).first
      raise Omega::DataNotFound, "manufactured entity specified by #{entity_id} not found" if entity.nil?

      event_callback =
        Callback.new(event, :endpoint => @headers['source_node']){ |*args|
          begin
            Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                       {:privilege => 'view', :entity => 'manufactured_entities'}],
                                              :session => @headers['session_id'])
            @rjr_callback.invoke 'manufactured::event_occurred', *args

          rescue Omega::PermissionError => e
            RJR::Logger.warn "client does not have privilege to subscribe to #{event} on #{entity.id}"
            entity.notification_callbacks.delete event_callback

          rescue RJR::Errors::ConnectionError => e
            RJR::Logger.warn "subscribe_to client disconnected"
            entity.notification_callbacks.delete event_callback
          end
        }

      old = entity.notification_callbacks.find { |n| n.type == event_callback.type &&
                                                     n.endpoint_id == event_callback.endpoint_id }

      unless old.nil?
       entity.notification_callbacks.delete(old)
      end

      entity.notification_callbacks << event_callback
      entity
    }

    rjr_dispatcher.add_handler('manufactured::remove_callbacks') { |entity_id|
      source_node = @headers['source_node']
      # FIXME verify request is coming from authenticated source node

      entity = Manufactured::Registry.instance.find(:id => entity_id).first
      raise Omega::DataNotFound, "entity specified by #{entity_id} not found" if entity.nil?
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                 {:privilege => 'view', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      entity.notification_callbacks.reject!{ |nc| nc.endpoint_id == source_node }
      entity
    }

    rjr_dispatcher.add_handler('manufactured::move_entity'){ |id, new_location|
      entity = Manufactured::Registry.instance.find(:id => id).first
      parent = @@local_node.invoke_request('cosmos::get_entity', 'of_type', :solarsystem, 'with_location', new_location.parent_id)

      raise ArgumentError, "invalid location #{new_location} specified" unless new_location.is_a?(Motel::Location)

      raise Omega::DataNotFound, "manufactured entity specified by #{id} not found"  if entity.nil?
      raise Omega::DataNotFound, "parent system specified by location #{new_location.id} not found" if parent.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # raise exception if entity or parent is invalid
      raise ArgumentError, "Must specify ship or station to move" unless entity.is_a?(Manufactured::Ship) || entity.is_a?(Manufactured::Station)
      raise ArgumentError, "Must specify system to move ship to"  unless parent.is_a?(Cosmos::SolarSystem)

      # update the entity's location
      entity.location = @@local_node.invoke_request('motel::get_location', entity.location.id)

      # if parents don't match, we are moving entity between systems
      if entity.parent.id != parent.id
        # if moving ship ensure it is within trigger distance of gate to new system and is not docked
        #   (TODO currently stations don't have this restriction though we may want to put others in place, or a transport delay / time)
        if entity.is_a?(Manufactured::Ship)
          near_jg = !entity.solar_system.jump_gates.select { |jg| jg.endpoint.name == parent.name &&
                                                                  (jg.location - entity.location) < jg.trigger_distance }.empty?
          raise Omega::OperationError, "Ship #{entity} not within triggering distance of a jump gate to #{parent}" unless near_jg
          raise Omega::OperationError, "Ship #{entity} is docked, cannot move" if entity.docked?
        end

        # simply set parent and location
        entity.parent   = parent
        new_location.id = entity.location.id
        entity.location = new_location
        @@local_node.invoke_request('motel::update_location', entity.location)
        # TODO remove all callbacks, not just those corresponding to @@local_node ???
        @@local_node.invoke_request('motel::remove_callbacks', entity.location.id, 'movement')
        @@local_node.invoke_request('motel::remove_callbacks', entity.location.id, 'proximity')

      # else move location within the system
      else
        # if moving ship, ensure it is not docked
        if entity.is_a?(Manufactured::Ship) && entity.docked?
          raise Omega::OperationError, "Ship #{entity} is docked, cannot move"
        end

        dx = new_location.x - entity.location.x
        dy = new_location.y - entity.location.y
        dz = new_location.z - entity.location.z
        distance = new_location - entity.location

        raise Omega::OperationError, "Ship or station #{entity} is already at location" if distance < 1

        # move to location using a linear movement strategy
        # FIXME derive speed from ship
        entity.location.movement_strategy =
          Motel::MovementStrategies::Linear.new :direction_vector_x => dx/distance,
                                                :direction_vector_y => dy/distance,
                                                :direction_vector_z => dz/distance,
                                                :speed => 5
        @@local_node.invoke_request('motel::update_location', entity.location)

        @@local_node.invoke_request('motel::track_movement', entity.location.id, distance)
      end

      entity
    }

    rjr_dispatcher.add_handler('manufactured::follow_entity'){ |id, target_id, distance|
      raise ArgumentError, "entity #{id} and target #{target_id} cannot be the same" if id == target_id

      entity = Manufactured::Registry.instance.find(:id => id).first
      target_entity = Manufactured::Registry.instance.find(:id => target_id).first

      raise Omega::DataNotFound, "manufactured entity specified by #{id} not found"  if entity.nil?
      raise Omega::DataNotFound, "manufactured entity specified by #{target_id} not found"  if target_entity.nil?

      raise ArgumentError, "distance must be an int / float > 0" if !distance.is_a?(Integer) && !distance.is_a?(Float) && distance <= 0

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{target_entity.id}"},
                                                 {:privilege => 'view', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # raise exception if entity or parent is invalid
      raise ArgumentError, "Must specify ship to move"           unless entity.is_a?(Manufactured::Ship)
      raise ArgumentError, "Must specify ship to follow"         unless target_entity.is_a?(Manufactured::Ship)

      # update the entities' locations
      entity.location = @@local_node.invoke_request('motel::get_location', entity.location.id)
      target_entity.location = @@local_node.invoke_request('motel::get_location', target_entity.location.id)

      # ensure entities are in the same system
      raise ArgumentError, "entity #{entity} must be in the same system as entity to follow #{target_entity}" if entity.location.parent.id != target_entity.location.parent.id

      # ensure entity isn't docked
      raise Omega::OperationError, "Ship #{entity} is docked, cannot move" if entity.docked?

      # FIXME derive speed from ship
      entity.location.movement_strategy =
        Motel::MovementStrategies::Follow.new :tracked_location_id => target_entity.location.id,
                                              :distance            => distance,
                                              :speed => 5

      @@local_node.invoke_request('motel::update_location', entity.location)

      entity
    }


    # callback to track_movement in update location
    rjr_dispatcher.add_handler('motel::on_movement') { |loc|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      entity = Manufactured::Registry.instance.find(:location_id => loc.id).first

      entity.location.update(loc)
      entity.location.movement_strategy = Motel::MovementStrategies::Stopped.instance
      @@local_node.invoke_request('motel::update_location', entity.location)
      @@local_node.invoke_request('motel::remove_callbacks', entity.location.id, :movement)
    }

    rjr_dispatcher.add_handler('manufactured::attack_entity'){ |attacker_entity_id, defender_entity_id|
      raise ArgumentError, "attacker and defender entities must be different" if attacker_entity_id == defender_entity_id

      attacker = Manufactured::Registry.instance.find(:id => attacker_entity_id, :type => "Manufactured::Ship").first
      defender = Manufactured::Registry.instance.find(:id => defender_entity_id, :type => "Manufactured::Ship").first

      raise Omega::DataNotFound, "ship specified by #{attacker_entity_id} (attacker) not found"  if attacker.nil?
      raise Omega::DataNotFound, "ship specified by #{defender_entity_id} (defender) not found"  if defender.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{attacker.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{defender.id}"},
                                                 {:privilege => 'view', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      attacker.location = @@local_node.invoke_request('motel::get_location', attacker.location.id)
      defender.location = @@local_node.invoke_request('motel::get_location', defender.location.id)

      raise Omega::OperationError, "#{attacker} cannot attack #{defender}" unless attacker.can_attack?(defender)

      Manufactured::Registry.instance.schedule_attack :attacker => attacker, :defender => defender

      [attacker, defender]
    }

    # TODO
    # rjr_dispatcher.add_handler('manufactured::stop_attack'){ |attacker_entity_id|

    rjr_dispatcher.add_handler('manufactured::dock') { |ship_id, station_id|
      ship    = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first
      station = Manufactured::Registry.instance.find(:id => station_id, :type => 'Manufactured::Station').first

      raise Omega::DataNotFound, "manufactured ship specified by #{ship_id} not found" if ship.nil?
      raise Omega::DataNotFound, "manufactured station specified by #{station_id} not found"  if station.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])
      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{station.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # update ship / station location
      ship.location = @@local_node.invoke_request('motel::get_location', ship.location.id)
      station.location = @@local_node.invoke_request('motel::get_location', station.location.id)

      raise Omega::OperationError, "#{ship} cannot dock at #{station}" unless station.dockable?(ship)

      # TODO not thread safe, should go through the registry
      # TODO station.add_docked_ship(ship)
      ship.dock_at(station)

      # set ship movement strategy to stopped
      # TODO we may want to set position of ship in proximity of station
      ship.location.movement_strategy = Motel::MovementStrategies::Stopped.instance
      @@local_node.invoke_request('motel::update_location', ship.location)

      ship
    }

    rjr_dispatcher.add_handler('manufactured::undock') { |ship_id|
      ship    = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first

      raise Omega::DataNotFound, "manufactured ship specified by #{ship_id} not found" if ship.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # TODO we may want to require a station's docking clearance at some point

      raise Omega::OperationError, "#{ship} is not docked, cannot undock" unless ship.docked?

      # TODO not thread safe, should go through the registry
      ship.undock
      ship
    }

    rjr_dispatcher.add_handler('manufactured::start_mining') { |ship_id, entity_id, resource_id|
      ship = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first
      # TODO how/where to incorporate resource scanning distance & capabilities into this
      resource_sources = @@local_node.invoke_request('cosmos::get_resource_sources', entity_id)
      resource_source  = resource_sources.find { |rs| rs.resource.id == resource_id }

      # TODO verify ship is not already mining resource, within mining distance
      raise Omega::DataNotFound, "ship specified by #{ship_id} not found" if ship.nil?
      raise Omega::DataNotFound, "resource_source specified by #{resource_source_id} not found" if resource_source.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # XXX don't like having to do this but need to load resource source's entity's location parent explicity
      resource_source.entity.location.parent = @@local_node.invoke_request('motel::get_location', resource_source.entity.location.parent_id)

      raise Omega::OperationError, "#{ship} cannot mine #{resource_source}" unless ship.can_mine?(resource_source)

      # resource_source is a copy of actual resource_source
      # stored in cosmos registry, need to update original
      collected_callback =
        Callback.new(:resource_collected, :endpoint => @@local_node.message_headers['source_node']){ |*args|
          rs = args[2]
          @@local_node.invoke_request('cosmos::set_resource', rs.entity.name, rs.resource, rs.quantity)
        }
      depleted_callback =
        Callback.new(:mining_stopped, :endpoint => @@local_node.message_headers['source_node']){ |*args|
          ship.notification_callbacks.delete collected_callback
          ship.notification_callbacks.delete depleted_callback
        }
      ship.notification_callbacks << collected_callback
      ship.notification_callbacks << depleted_callback

      Manufactured::Registry.instance.schedule_mining :ship => ship, :resource_source => resource_source
      ship
    }

    # TODO
    #rjr_dispatcher.add_handler('manufactured::stop_mining') { |ship_id|

    rjr_dispatcher.add_handler('manufactured::transfer_resource') { |from_entity_id, to_entity_id, resource_id, quantity|
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

      entities = Manufactured::Registry.instance.transfer_resource(from_entity, to_entity, resource_id, quantity)
      raise Omega::OperationError, "problem transferring resources from #{from_entity} to #{to_entity}" if entities.nil?
      entities
    }

    rjr_dispatcher.add_handler('manufactured::save_state') { |output|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      output_file = File.open(output, 'a+')
      Manufactured::Registry.instance.save_state(output_file)
      output_file.close
    }

    rjr_dispatcher.add_handler('manufactured::restore_state') { |input|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      input_file = File.open(input, 'r')
      Manufactured::Registry.instance.restore_state(input_file)
      input_file.close
    }


  end
end # class RJRAdapter

end # module Manufactured
