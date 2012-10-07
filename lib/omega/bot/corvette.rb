#!/usr/bin/ruby
# omega bot corvette ship tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'

module Omega
  module Bot
    class Corvette < Omega::Client::Ship
      # Return an array containing ordered list of systems with jump gates corresponding
      # to a path between from and to.
      #
      # TODO at some point factor in a shortest path algorthim
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

      # Calculate and return array containing path to visit all systems
      #
      # Assumes you can get to any given system from any other system
      def path
        systems = [@solar_system]
        systems.each { |s|
          s.jump_gates.each { |jg|
            ds = Omega::Client::Tracker[Omega::Client::SolarSystem.entity_type + '-' + jg.endpoint]
            ds = Omega::Client::SolarSystem.get(jg.endpoint) if ds.nil?
            systems << ds unless systems.include?(ds)
          }
        }

        full_path = []
        0.upto(systems.size-2) { |i|
          full_path += get_path(systems[i], systems[i+1])
          full_path.delete_at(-1)
        }
        full_path += get_path(systems[-1], systems[0])
        full_path.delete_at(-1)
        full_path
      end

      # Initialize path variables
      def init_path
        @full_path ||= path
        @current_system_index ||= @full_path.index(@solar_system)
      end

      # Check proximity & stop movement to attack if enemy ship is detected.
      #
      # TODO make algorithm smarter, just currently grabs all neighboring locations
      # and tries to retrieve enemy ships associated with them
      def check_proximity
        self.get
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
        schedule_proximity_cycle
        nil
      end

      # run proximity check cycle
      def schedule_proximity_cycle
        # TODO variable detection interval
        @proximity_timer =
          Omega::Client::Tracker.em_schedule_async(3){ self.check_proximity }
      end

      # XXX not the best way to do this, but works
      def on_event(event, &bl)
        if event == 'arrived_in_system'
          @arrived_in_system_callback = bl
          return
        end

        super(event, &bl)
      end

      def start
        init_path
        next_system = @full_path[@current_system_index + 1]
        jg = @solar_system.jump_gates.find { |jg| jg.endpoint == next_system.name }
        dst = ((self.entity.location - jg.location) < 15) ? 50 : 10
        move_to(:location => (jg.location + [dst,0,0])) { |c|
          c = jump_to next_system
          @current_system_index += 1
          @current_system_index = -1 if @current_system_index == (@full_path.size - 1)
          @arrived_in_system_callback.call c if @arrived_in_system_callback
          start
        }

        schedule_proximity_cycle
      end

      def self.get(id)
        corvette = super(id)

        corvette.on_event('attacked') { |event, attacker, defender|
          corvette.entity= attacker
          corvette.stop_moving
        }
        corvette.on_event('defended') { |event, attacker, defender|
          corvette.entity= defender
          corvette.stop_moving
          # start attacking if not already?
        }
        corvette.on_event('attacked_stop') { |event, attacker,defender|
          corvette.entity= attacker
          corvette.start
        }
        corvette.on_event('defended_stop') { |event, attacker,defender|
          corvette.entity= defender
          corvette.start
        }

        return corvette
      end

      def initialize(args = {})
        super(args)
      end

    end
  end
end
