# Omega client ship tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client2/mixins'
require 'omega/client2/bots'
require 'manufactured'

module Omega
  module Client
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

    class Corvette < Ship
      entity_validation { |e| e.type == 'corvette' }

      server_event       :attacked      => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" },
                         :attacked_stop => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" }

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
        handle(:attacked_stop){ |*args|
          self.patrol_route
        }
      end

      def patrol_route
        # add local system to visited list
        @visited << self.solar_system

        # add each local neighbors to the to_visit
        # list if not present in either list
        self.solar_system.jump_gates.each { |jg|
          unless @visited.find  { |sys| sys.name == jg.endpoint } ||
                 @to_visit.find { |sys| sys.name == jg.endpoint }
            @to_visit << Node.cached(jg.endpoint)
          end
        }

        # if no items in to_visit clear lists
        if @to_visit.empty?
          @visited  = []
          @to_visit = []
          patrol_route

        else
          visiting = @to_visit.shift
          jg = self.solar_system.jump_gates.find { |jg| jg.endpoint == visiting.name }

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

      def start_bot
        @visited  = []
        @to_visit = []

        self.patrol_route
      end
    end

    class Miner < Ship
      include TrackState

      entity_validation { |e| e.type == 'mining' }

      server_event       :resource_collected => { :subscribe    => "manufactured::subscribe_to",
                                                  :notification => "manufactured::event_occurred" },
                         :mining_stopped     => { :subscribe    => "manufactured::subscribe_to",
                                                  :notification => "manufactured::event_occurred" }

      server_state :cargo_full,
        :check => lambda { self.cargo_full?       },
        :on    => lambda { self.offload_resources },
        :off   => lambda {}

      def offload_resources
        st = closest(:station)
        raise_event(:moving_to, st)
        if st.location - self.location < self.transfer_distance
          transfer_all_to(st)
          self.select_target

        else
          move_to :destination => st { |*args|
            transfer_all_to(st)
            self.select_target
          }
        end
      end

      def select_target
        rs = closest(:resource)
        raise_event(:no_resources) if rs.nil?
        if rs.location - self.location < self.mining_distance
          rs = rs.resource_sources.find { |rsi| rsi.quantity > 0 }
          mine(rs)

        else
          dst = self.mining_distance / 4
          nl  = rs.location + [dst,dst,dst]
          move_to(:location => nl) { |*args| mine(rs) }
        end
      end

      def start_bot
        select_target
      end
    end

  end
end
