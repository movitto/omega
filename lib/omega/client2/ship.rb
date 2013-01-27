# Omega client ship tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO event rate throttling mechanisms:
#   - after threshold only process 1 out of every n events in raise_event
#   - flush queue if max events reached in raise_event
#   - delay new request until events go below threshold in invoke_request
#   - stop running actions on server side until queue is completed, then restart
#   - overwrite pending entity events w/ new events of the same type

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

      on_init { |corvette|
        @@corvettes ||= []
        @@corvettes << corvette

        @@proximity_thread ||= Thread.new {
          while true
            @corvettes.each { |c|
              c.check_proximity
            }
            sleep 10
          end
        }
      }

      # Start the omega client bot
      def start_bot
        @visited  = []

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
        @visited << self.solar_system unless @visited.include?(self.solar_system)

        # grab jump gate of a neighboring system we haven't visited yet
        jg = self.solar_system.jump_gates.find { |jg| !@visited.include?(jg.endpoint) }

        # if no items in to_visit clear lists
        if jg.nil?
          @visited  = []
          patrol_route

        else
          dst = jg.trigger_distance / 4
          nl  = jg.location + [dst,dst,dst]
          move_to(:location => nl) {
            self.jump_to(jg.endpoint)
            self.patrol_route
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
              handle_event(:attacked_stop){ |*args| self.patrol_route }
              attack(sh)
              break
            end
          rescue Exception => e
          end
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
        handle_event(:mining_stopped) { |*args|
          offload_resources
        }

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
          Node.raise_event(:moving_to, self, st)
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
          return
        else
          Node.raise_event(:selected_resource, self, rs)
        end

        if rs.location - self.location < self.mining_distance
          rs = rs.resource_sources.find { |rsi| rsi.quantity > 0 }

          # server resource may by depleted at any point, 
          # need to catch errors, and try elsewhere
          begin
            mine(rs)
          rescue Exception => e
            select_target
          end

        else
          dst = self.mining_distance / 4
          nl  = rs.location + [dst,dst,dst]
          rs  = rs.resource_sources.find { |rsi| rsi.quantity > 0 }
          move_to(:location => nl) { |*args|
            begin
              mine(rs)
            rescue Exception => e
              select_target
            end
          }
        end
      end

    end

  end
end
