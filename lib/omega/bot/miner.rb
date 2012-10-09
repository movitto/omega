#!/usr/bin/ruby
# omega bot miner ship tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'

module Omega
  module Bot
    class Miner < Omega::Client::Ship
      def valid?
        self.entity.is_a?(Manufactured::Ship) && self.type == :mining
      end

      def closest_resource
        # TODO check other systems
        self.solar_system.get
        rs = self.solar_system.asteroids.sort { |a,b| (self.location - a.location) <=>
                                                      (self.location - b.location) }.
                                     find { |a| !a.update!.resource_sources.find { |rs|
                                                              rs.quantity > 0 }.nil? }
        rs
      end

      def on_event(event, &bl)
        if event == 'moving_to_station'
          @moving_to_station_callback = bl
          return

        elsif event == 'arrived_at_station'
          @arrived_at_station_callback = bl
          return

        elsif event == 'arrived_at_resource'
          @arrived_at_resource_callback = bl
          return

        elsif event == 'selected_resource'
          @selected_resource_callback = bl
          return

        elsif event == 'no_more_resources'
          @no_more_resources_callback = bl
          return

        end

        super(event, &bl)
      end

      def move_to(args = {}, &bl)
        # TODO multisystem routes
        if args[:destination] == :closest_resource
          rs = closest_resource
          # raise Exception if rs.nil?
          nloc = rs.entity.location + 10
          args[:x] = nloc.x
          args[:y] = nloc.y
          args[:z] = nloc.z
          args.delete(:destination)
        end

        super(args, &bl)
      end

      def mine(args = {})
        target = args[:target]
        if target == :closest_resource
          target = closest_resource
          target = target.resource_sources.find { |rs| rs.quantity > 0 } unless target.nil?
        end

        # ensure target isn't nil
        if target.nil?
          @no_more_resources_callback.call self if @no_more_resources_callback
          return
        end

        # TODO ensurewe're within mining distance (else catch start_mining errors)
        Omega::Client::Tracker.invoke_request 'manufactured::start_mining',
                        self.entity.id, target.entity.name, target.resource.id

      end

      def move_to_and_mine(target)
        if target == :closest_resource
          target = closest_resource
          target = target.resource_sources.find { |rs| rs.quantity > 0 } unless target.nil?
        end

        # ensure target isn't nil
        if target.nil?
          @no_more_resources_callback.call self if @no_more_resources_callback
          return
        end

        @selected_resource_callback.call self, target if @selected_resource_callback

        dst = ((self.entity.location - target.entity.location) < 15) ? 50 : 10
        move_to(:location => (target.entity.location + [dst,0,0])) { |m,dst|
          @arrived_at_resource_callback.call m if @arrived_at_resource_callback
          mine :target => target
        }
      end

      def start
        init
        if self.cargo_full?
          @moving_to_station_callback.call self if @moving_to_station_callback

          move_to(:destination => :closest_station) { |m,dst|
            @arrived_at_station_callback.call m if @arrived_at_station_callback
            # FIXME ensure can transfer resources to station (which may have jumped)
            self.resources.each { |rsid, quantity|
              transfer quantity, :of => rsid, :to => dst
            }
            move_to_and_mine :closest_resource
          }

        else
          move_to_and_mine :closest_resource

        end
      end

      # Initialize miner
      def init
        return if @initialized

        @initialized = true
        # setup events
        self.on_event('mining_stopped') { |event,reason,miner,rs|
          # TODO ensure reason == 'cargo_full'
          entity = Omega::Client::Tracker[Omega::Client::Ship.entity_type + '-' + miner.id]
          entity.get
          entity.start
        }
      end
    end
  end
end
