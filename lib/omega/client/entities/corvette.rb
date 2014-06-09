# Omega Client Corvette Tracker
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/entities/ship'

module Omega
  module Client
    # Omega client corvette ship tracker
    class Corvette < Ship
      entity_validation { |e| e.type == :corvette }

      entity_event \
        :attacked =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'attacked' && a[1].id == entity.id
            }},

        :attacked_stop =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'attacked_stop' && a[1].id == entity.id
            }}

      # Run proximity checks via an external thread for all corvettes
      # upon first corvette intialization
      #
      # TODO introduce a centralized entity tracking cycle
      # via mixin and utilize that here
      entity_init { |corvette|
        @@corvettes ||= []
        @@corvettes << corvette

        @@proximity_thread ||= Thread.new {
          while true
            @@corvettes.each { |c|
              c.check_proximity
            }
            sleep 10
          end
        }
      }

      # Attack the specified target
      #
      # All server side attack restrictions apply, this method does
      # not do any checks b4 invoking attack_entity so if server raises
      # a related error, it will be reraised here
      #
      # @param [Manufactured::Ship,Manufactured::Station] target entity to attack
      def attack(target)
        RJR::Logger.info "Starting to attack #{target.id} with #{id}"
        node.invoke 'manufactured::attack_entity', id, target.id
      end

      # visited systems
      attr_accessor :visited

      # Start the omega client bot
      def start_bot
        handle(:destroyed_by)
        patrol_route
      end

      # Calculate an inter-system route to patrol and move through it.
      def patrol_route
        @visited  ||= []

        # add local system to visited list
        @visited << solar_system unless @visited.include?(solar_system)

        # grab jump gate of a neighboring system we haven't visited yet
        jg = solar_system.jump_gates.find { |jg|
               !@visited.collect { |v| v.id }.include?(jg.endpoint_id)
             }

        # if no items in to_visit clear lists
        if jg.nil?
          # if jg can't be found on two subsequent runs,
          # error out / stop bot
          if @patrol_err
            raise_event(:patrol_err)
            return
          end
          @patrol_err = true

          @visited  = []
          patrol_route

        else
          @patrol_err = false
          raise_event(:selected_system, jg.endpoint_id, jg)
          if jg.location - location < jg.trigger_distance
            jump_to(jg.endpoint)
            patrol_route

          else
            dst = jg.trigger_distance / 4
            nl  = jg.location + [dst,dst,dst]
            move_to(:location => nl) {
              jump_to(jg.endpoint)
              patrol_route
            }
          end
        end
      end

      # Internal helper, check nearby locations, if enemy ship is detected
      # stop movement and attack it. Result patrol route when attack ceases
      def check_proximity
        solar_system.entities.each { |e|
          if e.is_a?(Manufactured::Ship) && e.user_id != user_id &&
             e.location - location <= attack_distance && e.alive?
            stop_moving
            unless @check_proximity_handler
              @check_proximity_handler = true
              handle(:attacked_stop){ |*args| patrol_route }
            end
            attack(e)
            break
          end
        } if self.alive? && !self.attacking?
      end
    end # class Corvette
  end # module Client
end # module Omega
