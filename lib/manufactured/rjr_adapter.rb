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
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'create', 'locations')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'view',   'users_entities')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'view',   'locations')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'modify', 'locations')

    session = @@local_node.invoke_request('users::login', self.user)
    @@local_node.message_headers['session_id'] = session.id
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('manufactured::create_entity'){ |entity|
      Users::Registry.require_privilege(:privilege => 'create', :entity => 'manufactured_entities',
                                        :session   => @headers['session_id'])

      # swap out the parent w/ the one stored in the cosmos registry
      if !entity.is_a?(Manufactured::Fleet) && entity.parent
        parent = @@local_node.invoke_request('cosmos::get_entity', :solarsystem, entity.parent.name)
        raise Omega::DataNotFound, "parent system specified by #{entity.parent.name} not found" if parent.nil?
        entity.parent = parent
      end

      Manufactured::Registry.instance.create entity

      unless entity.is_a?(Manufactured::Fleet) || entity.location.nil?
        entity.location = @@local_node.invoke_request('create_location', entity.location)
      end

      entity
    }

    rjr_dispatcher.add_handler('manufactured::get_entity'){ |id|
       entity = Manufactured::Registry.instance.find(:id => id).first
       raise Omega::DataNotFound, "manufactured entity specified by #{id} not found" if entity.nil?

       entity.location = @@local_node.invoke_request('get_location', entity.location.id)
       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                  {:privilege => 'view', :entity => 'manufactured_entities'}],
                                         :session => @headers['session_id'])

       entity
    }

    rjr_dispatcher.add_handler('manufactured::get_entities_under'){ |parent_id|
      # just lookup parent to ensure it exists
      parent = @@local_node.invoke_request('cosmos::get_entity', :solarsystem, parent_id)
      raise Omega::DataNotFound, "parent system specified by #{parent_id} not found" if parent.nil?

      entities = Manufactured::Registry.instance.find(:parent_id => parent_id)
      entities.reject! { |entity|
        raised = false
        begin
          Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                     {:privilege => 'view', :entity => 'manufactured_entities'}],
                                            :session => @headers['session_id'])
        rescue Omega::PermissionError => e
          raised = true
        end
        raised
      }
      entities.each { |entity|
        unless entity.is_a?(Manufactured::Fleet)
          entity.location = @@local_node.invoke_request('get_location',
                                                        entity.location.id)
        end
      }
      entities
    }

    rjr_dispatcher.add_handler('manufactured::get_entities_for_user') { |user_id, entity_type|
      # just lookup user to ensure it exists
      user = @@local_node.invoke_request('users::get_entity', user_id)
      raise Omega::DataNotFound, "user specified by #{user_id} not found" if user.nil?

      entities = Manufactured::Registry.instance.find(:type => entity_type, :user_id => user_id)
      entities.reject! { |entity|
        raised = false
        begin
          Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                     {:privilege => 'view', :entity => 'manufactured_entities'}],
                                            :session => @headers['session_id'])
        rescue Omega::PermissionError => e
          raised = true
        end
        raised
      }
      entities.each { |entity|
        unless entity.is_a?(Manufactured::Fleet)
          entity.location = @@local_node.invoke_request('get_location', entity.location.id)
        end
      }
      entities
    }

    rjr_dispatcher.add_handler('manufactured::subscribe_to') { |entity_id, event|
      entity = Manufactured::Registry.instance.find(:id => entity_id).first
      raise Omega::DataNotFound, "manufactured entity specified by #{entity_id} not found" if entity.nil?

      event_callback =
        Callback.new(event){ |*args|
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

      entity.notification_callbacks << event_callback
      entity
    }

    rjr_dispatcher.add_handler('manufactured::move_entity'){ |id, new_location|
      entity = Manufactured::Registry.instance.find(:id => id).first
      parent = @@local_node.invoke_request('cosmos::get_entity_from_location', :solarsystem, new_location.parent_id)

      raise Omega::DataNotFound, "manufactured entity specified by #{id} not found"  if entity.nil?
      raise Omega::DataNotFound, "parent system specified by location #{new_location.id} not found" if parent.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # raise exception if entity or parent is invalid
      raise ArgumentError, "Must specify ship to move"           unless entity.is_a?(Manufactured::Ship)
      raise ArgumentError, "Must specify system to move ship to" unless parent.is_a?(Cosmos::SolarSystem)

      # if parents don't match, simply set parent and location
      if entity.parent.id != parent.id
        entity.parent   = parent
        new_location.id = entity.location.id
        entity.location = new_location
        @@local_node.invoke_request('update_location', entity.location)

      # else move to location using a linear movement strategy
      else
        dx = new_location.x - entity.location.x
        dy = new_location.y - entity.location.y
        dz = new_location.z - entity.location.z
        distance = Math.sqrt( dx ** 2 + dy ** 2 + dz ** 2 )

        # FIXME derive speed from ship
        entity.location.movement_strategy =
          Motel::MovementStrategies::Linear.new :direction_vector_x => dx/distance,
                                                :direction_vector_y => dy/distance,
                                                :direction_vector_z => dz/distance,
                                                :speed => 1
        @@local_node.invoke_request('update_location', entity.location)

        @@local_node.invoke_request('track_movement', entity.location.id, distance)
      end

      entity
    }

    # callback to track_proximity in update location
    rjr_dispatcher.add_handler('on_movement') { |loc|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      entity = Manufactured::Registry.instance.find(:location_id => loc.id).first

      entity.location.movement_strategy = Motel::MovementStrategies::Stopped.instance
      @@local_node.invoke_request('update_location', entity.location)
      @@local_node.invoke_request('remove_callbacks', entity.location.id, :movement)
    }

    rjr_dispatcher.add_handler('manufactured::attack_entity'){ |attacker_entity_id, defender_entity_id|
      attacker = Manufactured::Registry.instance.find(:id => attacker_entity_id).first
      defender = Manufactured::Registry.instance.find(:id => defender_entity_id).first

      raise Omega::DataNotFound, "manufactured entity specified by #{attacker_entity_id} (attacker) not found"  if attacker.nil?
      raise Omega::DataNotFound, "manufactured entity specified by #{defender_entity_id} (defender) not found"  if defender.nil?

      # TODO verify entities are within attacking distance

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{attacker.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{defender.id}"},
                                                 {:privilege => 'view', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      Manufactured::Registry.instance.schedule_attack :attacker => attacker, :defender => defender

      [attacker, defender]
    }

    # TODO
    # rjr_dispatcher.add_handler('manufactured::stop_attack'){ |attacker_entity_id|

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

      ship.dock_at(station)
      ship
    }

    rjr_dispatcher.add_handler('manufactured::undock') { |ship_id|
      ship    = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first

      raise Omega::DataNotFound, "manufactured ship specified by #{ship_id} not found" if ship.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])
      ship.undock
      ship
    }

  end
end # class RJRAdapter

end # module Manufactured
