#!/usr/bin/ruby
# omega bot miner ship tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'

module Omega
  module Bot
    class Miner < Omega::Client::Ship
      def closest_resource
        # TODO check other systems
        @solar_system.sync
        rs = @solar_system.asteroids.select { |a|
               !a.resource_sources.find { |rs| rs.quantity > 0 }.nil?
             }.sort { |a,b| (self.location - a.location) <=> 
                            (self.location - b.location) }.first
        rs
      end

      # XXX not the best way to do this, but works
      def on_event(event, &bl)
        if event == 'arrived_at_station'
          @arrived_at_station_callback = bl
          return

        elsif event == 'arrived_at_resource'
          @arrived_at_resource_callback = bl
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
          target = closest_resource.resource_sources.find { |rs| rs.quantity > 0 }
        end
        # TODO ensure target isn't nil & we're within mining distance (else catch start_mining errors)

        Omega::Client::Tracker.instance.invoke_request 'omega-queue',
                            'manufactured::start_mining', @entity.id,
                              target.entity.name, target.resource.id
                                    
      end

      def move_to_and_mine(target)
        if target == :closest_resource
          target = closest_resource.resource_sources.find { |rs| rs.quantity > 0 }
        end
        # TODO ensure target isn't nil & we're not within mining distance

        move_to(:location => (target.entity.location + 10)) { |m|
          @arrived_at_resource_callback.call m if @arrived_at_resource_callback
          mine :target => target
        }
      end

      def start
        if self.cargo_full?
          move_to(:destination => :closest_station) { |m|
            @arrived_at_station_callback.call m if @arrived_at_station_callback
            resources.each { |rsid, quantity|
              transfer quantity, :of => rsid, :to => :closest_station
            }
            move_to_and_mine :closest_resource
          }

        else
          move_to_and_mine :closest_resource

        end
      end

      def self.get(id)
        miner = super(id)

        # setup events
        miner.on_event('mining_stopped') { |*args|
          # TODO ensure reason == 'cargo_full'
          Omega::Client::Tracker[Omega::Client::Ship.entity_type + '-' + miner.id].start
        }

        return miner
      end

    end
  end
end
