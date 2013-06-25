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

require 'omega/client/mixins'
require 'omega/client/entities/location'
require 'omega/client/entities/cosmos'
require 'omega/client/entities/station'
require 'manufactured/ship'

module Omega
  module Client
    # Omega client Manufactured::Ship tracker
    class Ship
      include Trackable
      include TrackEntity
      include HasLocation
      include InSystem
      include HasCargo

      entity_type  Manufactured::Ship

      get_method   "manufactured::get_entity"

      entity_event :defended      => { :subscribe    => "manufactured::subscribe_to",
                                       :notification => "manufactured::event_occurred" },
                   :defended_stop => { :subscribe    => "manufactured::subscribe_to",
                                       :notification => "manufactured::event_occurred" }

      # Dock at the specified station
      def dock_to(station)
        RJR::Logger.info "Docking #{id} at #{station.id}"
        node.invoke 'manufactured::dock', id, station.id
      end

      # Undock
      def undock
        RJR::Logger.info "Unocking #{id}"
        node.invoke 'manufactured::undock', id
      end

      # Collect specified loot
      #
      # @param [Manufactured::Loot] loot loot which to collect
      def collect_loot(loot)
        RJR::Logger.info "Entity #{id} collecting loot #{loot.id}"
        @entity = node.invoke 'manufactured::collect_loot', id, loot.id
      end
    end

    # Omega client miner ship tracker
    class Miner < Ship
      include TrackState

      entity_validation { |e| e.type == :mining }

      entity_event  :resource_collected => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" },
                    :mining_stopped     => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" }

      server_state :cargo_full,
        :check => lambda { |e| e.cargo_full?       },
        :on    => lambda { |e| e.offload_resources },
        :off   => lambda { |e| }

      # Mine the specified resource
      #
      # All server side mining restrictions apply, this method does
      # not do any checks b4 invoking start_mining so if server raises
      # a related error, it will be reraised here
      #
      # @param [Cosmos::Resource] resourceresource to start mining
      def mine(resource)
puts "mining #{resource} #{id}"
        RJR::Logger.info "Starting to mine #{resource.id} with #{id}"

        # handle resource collected of entity.mining quantity, invalidating
        # client side cached copy of resource source
        unless handles?(:resource_collected)
          handle(:resource_collected) { |*args|
            # TODO update resources locally, invalidate asteroid resources
          }
        end

        node.invoke 'manufactured::start_mining', id, resource.id
      end

      # Start the omega client bot
      def start_bot
        handle(:mining_stopped) { |*args|
          offload_resources
        }

        if cargo_full?
          offload_resources
        else
          select_target
        end
      end

      # Move to the closest station owned by user and transfer resources to it
      def offload_resources
        st = closest(:station).first
        if st.location - location < transfer_distance
          transfer_all_to(st)
          select_target

        else
          raise_event(:moving_to, self, st)
          move_to(:destination => st) { |*args|
            transfer_all_to(st)
            select_target
          }
        end
      end

      # Select next resource, move to it, and commence mining
      def select_target
        ast = closest(:resource).first
        if ast.nil?
          raise_event(:no_resources, self)
          return
        else
          raise_event(:selected_resource, self, ast)
        end

        rs  = ast.resources.find { |rsi| rsi.quantity > 0 }

        if ast.location - location < mining_distance
          # server resource may by depleted at any point, 
          # need to catch errors, and try elsewhere
          begin
            mine(rs)
          rescue Exception => e
            select_target
          end

        else
          dst = mining_distance / 4
          nl  = ast.location + [dst,dst,dst]
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

    # Omega client corvette ship tracker
    class Corvette < Ship
      entity_validation { |e| e.type == :corvette }

      entity_event       :attacked      => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" },
                         :attacked_stop => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" }

    #  # Run proximity checks via an external thread for all corvettes
    #  # upon first corvette intialization
    #  #
    #  # TODO introduce a centralized entity thread & cycling management system
    #  # in node / mixins and utilize that here
    #  on_init { |corvette|
    #    @@corvettes ||= []
    #    @@corvettes << corvette

    #    @@proximity_thread ||= Thread.new {
    #      while true
    #        @corvettes.each { |c|
    #          c.check_proximity
    #        }
    #        sleep 10
    #      end
    #    }
    #  }

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
        @visited  = []

        patrol_route
      end

      # Calculate an inter-system route to patrol and move through it.
      def patrol_route
        # add local system to visited list
        @visited << solar_system unless @visited.include?(solar_system)

        # grab jump gate of a neighboring system we haven't visited yet
        jg = solar_system.jump_gates.find { |jg|
               !@visited.collect { |v| v.id }.include?(jg.endpoint_id)
             }

        # if no items in to_visit clear lists
        if jg.nil?
          @visited  = []
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

      # Internal helper, check nearby locations, if enemy ship is detected
      # stop movement and attack it. Result patrol route when attack ceases
      def check_proximity
        neighbors = node.invoke 'motel::get_locations',
                                'within', attack_distance,
                                           'of', location
        neighbors.each { |loc|
          begin
            sh = node.invoke 'manufactured::get_entity',
                        'of_type', 'Manufactured::Ship',
                               'with_location', loc.id
            unless sh.nil? || sh.user_id == user_id # TODO respect alliances
              stop_moving
              handle(:attacked_stop){ |*args| patrol_route }
              attack(sh)
              break
            end
          rescue Exception => e
          end
        }
      end
    end
  end
end
