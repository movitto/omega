# Omega client ship tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client2/mixins'
require 'manufactured'

module Omega
  module Client
    # Omega client Manufactured::Ship tracker
    class Ship
      include RemotelyTrackable
      include HasLocation
      include InSystem
      include InteractsWithEnvironment

      entity_type  Manufactured::Ship

      get_method   "manufactured::get_entity"

      server_event       :defended      => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" },
                         :defended_stop => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" },
                         :transferred   => {}
    end

    # Omega client corvette ship tracker
    class Corvette < Ship
      entity_validation { |e| e.type == :corvette }

      server_event       :attacked      => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" },
                         :attacked_stop => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" }

      # Start the omega client bot
      def start_bot
        @visited  = []
        @to_visit = []

        self.patrol_route
      end

      #private

      # Internal helper, calculate an inter-system route to patrol
      # and move through it.
      #
      # Periodically will check nearby locations for enemies
      # @see check_proximity below
      def patrol_route
        # add local system to visited list
        @visited << self.solar_system

        # add each local neighbors to the to_visit
        # list if not present in either list
        self.solar_system.jump_gates.each { |jg|
          unless @visited.find  { |sys| sys.name == jg.endpoint } ||
                 @to_visit.find { |sys| sys.name == jg.endpoint }
            # TODO move this into Omega::Client::Node.set_result
            jg.endpoint = Omega::Client::SolarSystem.cached(jg.endpoint) if jg.endpoint.is_a?(String)
            @to_visit << jg.endpoint
          end
        }

        # if no items in to_visit clear lists
        if @to_visit.empty?
          @visited  = []
          @to_visit = []
          patrol_route

        else
          visiting = @to_visit.shift
          jg = self.solar_system.jump_gates.find { |jg| jg.endpoint.name == visiting.name }

          dst = jg.trigger_distance / 4
          nl  = jg.location + [dst,dst,dst]
          move_to(:location => nl)
          
          handle_event(:movement, 10) { |*args|
            if(self.location - jg.location <= dst)
              self.jump_to(visiting)
              self.patrol_route

            else
              self.check_proximity
            end
          }
        end
      end


      # Internal helper, check nearby locations, if enemy ship is detected
      # stop movement and attack it. Result patrol route when attack ceases
      def check_proximity
        neighbors = Node.invoke_request 'motel::get_locations',
                                'within', self.attack_distance,
                                           'of', self.location
        neighbors.each { |loc|
          begin
            sh = Node.invoke_request 'manufactured::get_entity',
                                'of_type', 'Manufactured::Ship',
                                       'with_location', loc.id
            unless sh.nil? || sh.user_id == Node.user.id # TODO respect alliances
              self.stop_moving
              attack(sh)
              break
            end
          rescue Exception => e
          end
        }

        return if @continue_patrol
        @continue_patrol = true
        handle_event(:attacked_stop){ |*args|
          self.patrol_route
        }
      end
    end

    # Omega client miner ship tracker
    class Miner < Ship
      include TrackState

      entity_validation { |e| e.type == :mining }

      server_event       :resource_collected => { :subscribe    => "manufactured::subscribe_to",
                                                  :notification => "manufactured::event_occurred" },
                         :mining_stopped     => { :subscribe    => "manufactured::subscribe_to",
                                                  :notification => "manufactured::event_occurred" }

      server_state :cargo_full,
        :check => lambda { |e| e.cargo_full?       },
        :on    => lambda { |e| e.offload_resources },
        :off   => lambda { |e|}

      # Start the omega client bot
      def start_bot
        if self.cargo_full?
          offload_resources
        else
          select_target
        end
      end

      #private

      # Internal helper, move to the closest station owned by user and
      # transfer resources to it
      def offload_resources
        st = closest(:station).first
        if st.location - self.location < self.transfer_distance
          transfer_all_to(st)
          self.select_target

        else
          Node.raise_event(:moving_to, st)
          move_to(:destination => st) { |*args|
            transfer_all_to(st)
            self.select_target
          }
        end
      end

      # Internal helper, select next resource, move to it, and commence mining
      def select_target
        rs = closest(:resource).first
        if rs.nil?
          Node.raise_event(:no_resources, self)
        else
          Node.raise_event(:selected_resource, self, rs)
        end

        if rs.location - self.location < self.mining_distance
          rs = rs.resource_sources.find { |rsi| rsi.quantity > 0 }
          mine(rs)

        else
          dst = self.mining_distance / 4
          nl  = rs.location + [dst,dst,dst]
          rs  = rs.resource_sources.find { |rsi| rsi.quantity > 0 }
          move_to(:location => nl) { |*args|
            mine(rs)
          }
        end
      end

    end

  end
end
