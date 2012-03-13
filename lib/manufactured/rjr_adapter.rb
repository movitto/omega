# Manufactured rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'active_support/inflector'

module Manufactured

class RJRAdapter
  def self.init
    #Manufactured::Registry.instance.init
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('manufactured::create_entity'){ |entity|
       RJR::Logger.info "received create entity #{entity} request"
       begin
         # swap out the parent w/ the one stored in the cosmos registry
         if !entity.is_a?(Manufactured::Fleet) && entity.parent
           entity.parent = Cosmos::Registry.instance.find_entity :type => :solarsystem,
                                                                 :name => entity.parent.name
         end

         Manufactured::Registry.instance.create entity

         unless entity.is_a?(Manufactured::Fleet) || entity.location.nil?
           #unless entity.parent.nil? || entity.parent.location.nil?
           #  entity.location.parent
           #end
           Motel::Runner.instance.run entity.location
         end

       rescue Exception => e
         RJR::Logger.warn "request create entity #{entity} failed with exception #{e}"
       end
       RJR::Logger.info "request create entity returning #{entity}"
       entity
    }

    rjr_dispatcher.add_handler('manufactured::get_entity'){ |id|
       RJR::Logger.info "received get entity #{id} request"
       entity = nil
       begin
         entity = Manufactured::Registry.instance.find(:id => id).first
       rescue Exception => e
         RJR::Logger.warn "request get entity #{id} failed with exception #{e}"
       end
       RJR::Logger.info "request get entity #{id} returning #{entity}"
       entity
    }

    rjr_dispatcher.add_handler('manufactured::get_entities_under'){ |parent_id|
       RJR::Logger.info "received get_entities_under #{parent_id} request"
       entities = []
       begin
         entities = Manufactured::Registry.instance.find(:parent_id => parent_id)
       rescue Exception => e
         RJR::Logger.warn "request get_entities_under #{parent_id} failed with exception #{e}"
       end
       RJR::Logger.info "request get_entities_under #{parent_id} returning #{entities}"
       entities
    }

    rjr_dispatcher.add_handler('manufactured::get_entities_for_user') { |user_id, entity_type|
       RJR::Logger.info "received get get entities of #{entity_type} for user #{user_id}"
       entities = []
       begin
         entities = Manufactured::Registry.instance.find(:type => entity_type, :user_id => user_id)
       rescue Exception => e
         RJR::Logger.info "request get get entities of #{entity_type} for user #{user_id} failed with exception #{e}"
       end
       RJR::Logger.info "request get get entities of #{entity_type} for user #{user_id} returning #{entities}"
       entities
    }

    rjr_dispatcher.add_handler('manufactured::subscribe_to') { |entity_id, event|
       RJR::Logger.info "received subscribe_to #{entity_id} #{event} request"
       begin
         entity = Manufactured::Registry.instance.find(:id => entity_id).first
         event_callback =
           Callback.new(event){ |*args|
             begin
               @rjr_callback.invoke *args
             rescue RJR::Errors::ConnectionError => e
               RJR::Logger.warn "subscribe_to client disconnected"
               entity.notification_callbacks.delete event_callback
             end
           }

         entity.notification_callbacks << event_callback
       rescue Exception => e
         RJR::Logger.info "subscribe_to #{entity_id} #{event} failed with exception #{e}"
       end
       RJR::Logger.info "subscribe_to #{entity_id} #{event} request returning"
       nil
    }

    rjr_dispatcher.add_handler('manufactured::move_entity'){ |id, parent_id, new_location|
       RJR::Logger.info "received move entity #{id} to location #{new_location} under parent #{parent_id} request"
       begin
         entity = Manufactured::Registry.instance.find(:id => id).first
         parent = Cosmos::Registry.instance.find_entity :type => :solarsystem, :name => parent_id

         # raise exception if entity or parent is invalid
         raise ArgumentError, "Must specify ship to move" if entity.nil? || !entity.is_a?(Manufactured::Ship)
         raise ArgumentError, "Must specify system to move ship to" if parent.nil? || !parent.is_a?(Cosmos::SolarSystem)

         # if parents don't match, simply set parent and location
         if entity.parent.id != parent_id
           entity.parent   = parent
           entity.location = new_location unless new_location.nil?
           # TODO set locaiton parent

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
                                                   :speed => 5

           # stop on arrival
           on_proximity = Motel::Callbacks::Proximity.new :to_location  => new_location,
                                                   :event        => :proximity,
                                                   :max_distance => 10,
                                                   :handler      => lambda { |location1, location2|
             entity.location.movement_strategy = Motel::MovementStrategies::Stopped.instance
             entity.location.proximity_callbacks.clear
           }
           entity.location.proximity_callbacks << on_proximity

         end

       rescue Exception => e
         RJR::Logger.warn "request move entity #{entity} to location #{new_location} under parent #{parent} failed with exception #{e}"
       end
       RJR::Logger.info "request move entity #{entity} to location #{new_location} under parent #{parent} returning #{entity}"
       entity
    }

    rjr_dispatcher.add_handler('manufactured::attack_entity'){ |attacker_entity_id, defender_entity_id|
       RJR::Logger.info "received attack_entity #{defender_entity_id} (attacker #{attacker_entity_id})"
       begin
         attacker = Manufactured::Registry.instance.find(:id => attacker_entity_id).first
         defender = Manufactured::Registry.instance.find(:id => defender_entity_id).first
         Manufactured::Registry.instance.schedule_attack :attacker => attacker, :defender => defender

       rescue Exception => e
         RJR::Logger.info "request attack_entity #{defender_entity_id} (attacker #{attacker_entity_id}) returning failed with exception #{e}"
       end
       RJR::Logger.info "request attack_entity #{defender_entity_id} (attacker #{attacker_entity_id}) returning"
       nil
    }
  end
end # class RJRAdapter

end # module Manufactured
