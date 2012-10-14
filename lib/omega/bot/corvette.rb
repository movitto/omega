#!/usr/bin/ruby
# omega bot corvette ship tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'

module Omega
  module Bot
    class Corvette < Omega::Client::Ship

      def valid?
        self.entity.is_a?(Manufactured::Ship) && self.type == :corvette
      end

      # Return an array containing ordered list of systems with jump gates corresponding
      # to a path between from and to.
      #
      # TODO at some point factor in a shortest path algorthim.
      # TODO this should really be defined in another class/module
      def get_path(from, to, visited=[])
        from.jump_gates.each { |jg|
          ds = Omega::Client::Tracker[Omega::Client::SolarSystem.entity_type + '-' + jg.endpoint]
          ds = Omega::Client::SolarSystem.get(jg.endpoint) if ds.nil?
          unless visited.include?(ds)
            visited << ds 
            return [from, ds] if to.name == ds.name
            p = get_path(ds, to, visited)
            return [from] + p unless p.nil?
          end
        }
        return nil
      end

      # Calculate and return array containing all systems accessible from the
      # current one.
      #
      # TODO this should really be defined in another class/module
      def accessible_systems
        systems = [self.solar_system]
        systems.each { |s|
          s.jump_gates.each { |jg|
            ds = Omega::Client::Tracker[Omega::Client::SolarSystem.entity_type + '-' + jg.endpoint]
            ds = Omega::Client::SolarSystem.get(jg.endpoint) if ds.nil?
            systems << ds unless systems.include?(ds)
          }
        }
        systems
      end

      # Return path containing route to all accessible systems
      #
      # Assumes you can get to any given system from any other system.
      # TODO this should really be defined in another class/module
      def full_path
        fp = []
        systems = accessible_systems
        0.upto(systems.size-2) { |i|
          fp += get_path(systems[i], systems[i+1])
          fp.delete_at(-1)
        }
        fp += get_path(systems[-1], systems[0])
        fp.delete_at(-1)
        fp
      end

      # Check proximity & stop movement to attack if enemy ship is detected.
      #
      # TODO make algorithm smarter, just currently grabs all neighboring locations
      # and tries to retrieve enemy ships associated with them
      def check_proximity
        self.get_associated
        neighbors = Omega::Client::Tracker.invoke_request 'motel::get_locations',
                      'within', self.attack_distance, 'of', self.location.entity
        neighbors.each { |loc|
          begin
            sh = Omega::Client::Tracker.invoke_request 'manufactured::get_entity',
                         'of_type', 'Manufactured::Ship', 'with_location', loc.id
            # TODO respect alliances
            unless sh.nil? || sh.user_id == self.user_id
              stop_moving
              entities = Omega::Client::Tracker.invoke_request 'manufactured::attack_entity',
                                                                self.id, sh.id
              self.entity= entities.first
              return
            end
          
          rescue Exception => e
          end
        }
        # TODO ensure we are moving, else call start
        nil
      end

      # run proximity check cycle
      def self.schedule_proximity_cycle
        # TODO variable detection interval
        Omega::Client::Tracker.em_schedule_async(15){
          Omega::Client::Tracker.select { |k,v|
            k =~ /#{Omega::Client::Ship.entity_type}-.*/ &&
            v.type == :corvette
          }.each { |k,sh|
            sh.check_proximity
          }
          self.schedule_proximity_cycle
        }
      end

      def on_event(event, &bl)
        if event == 'arrived_in_system'
          @arrived_in_system_callback = bl
          return

        elsif event == 'selected_next_system'
          @selected_next_system_callback = bl
          return
        end

        super(event, &bl)
      end

      def start
        init

        @systemi = @patrol_route.index(self.solar_system) if @patrol_route[@systemi] != self.solar_system
        next_system = (@systemi == (@patrol_route.size - 1)) ?
                       @patrol_route[0] : @patrol_route[@systemi+1]
        jg = self.solar_system.jump_gates.find { |jg| jg.endpoint == next_system.name }
        @selected_next_system_callback.call self, next_system, jg if @selected_next_system_callback

        if jg.location - self.location.entity < jg.trigger_distance
          c = jump_to next_system
          @systemi += 1
          @arrived_in_system_callback.call c if @arrived_in_system_callback
          start

        else
          dst = jg.trigger_distance / 4
          move_to(:location => (jg.location + [dst,dst,dst])) { |c,dst|
            start
          }
        end

        @@proximity_timer  ||= self.class.schedule_proximity_cycle
      end

      # Initialize corvette
      def init
        #self.get
        #self.get_associated

        return if @initialized
        @initialized = true
        @patrol_route = full_path
        @systemi = 0

        self.on_event('attacked') { |event, attacker, defender|
          self.entity= attacker
          #self.get_associated
          self.stop_moving
        }
        self.on_event('defended') { |event, attacker, defender|
          self.entity= defender
          #self.get_associated
          self.stop_moving
          # start attacking if not already?
        }
        self.on_event('attacked_stop') { |event, attacker,defender|
          self.entity= attacker
          #self.get_associated
          self.start
        }
        self.on_event('defended_stop') { |event, attacker,defender|
          self.entity= defender
          #self.get_associated
          self.start
        }
      end
    end
  end
end
