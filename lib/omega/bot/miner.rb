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

      def mine(target)
        # TODO catch start_mining errors
        Omega::Client::Tracker.invoke_request 'manufactured::start_mining',
                        self.entity.id, target.entity.name, target.resource.id

      end

      def start
        init
        if self.cargo_full?
          @stations_to_try    ||= closest_stations
          @moving_to_station  ||= @stations_to_try.first
          @moving_to_station_callback.call self, @moving_to_station if @moving_to_station_callback

          if self.location - @moving_to_station.location < self.transfer_distance
            @arrived_at_station_callback.call self if @arrived_at_station_callback
            begin
              self.resources.each { |rsid, quantity|
                transfer quantity, :of => rsid, :to => @moving_to_station
              }
              @stations_to_try = @moving_to_station = nil

            rescue Exception => e
              if @moving_to_station == @stations_to_try.last
                @stations_to_try   = @moving_to_station = nil

              else
                @moving_to_station =
                   @stations_to_try[@stations_to_try.index(@moving_to_station)+1]
              end
            end

            start

          else
            move_to(:destination => @moving_to_station) { |m,dst|
              start
            }
          end

        else
          rs = closest_resource
          if rs.nil?
            @no_more_resources_callback.call self if @no_more_resources_callback

          elsif self.location.entity - rs.entity.location < self.mining_distance
            rs = rs.resource_sources.find { |rsi| rsi.quantity > 0 }
            @selected_resource_callback.call self, rs if @selected_resource_callback
            # TODO rescue mining errs?
            mine rs

          else
            dst = self.mining_distance / 4
            nl  = rs.entity.location + [dst,dst,dst]
            rs = rs.resource_sources.find { |rsi| rsi.quantity > 0 }
            @selected_resource_callback.call self, rs if @selected_resource_callback
            self.move_to(:location => nl) { |c,dest|
              start
            }

          end

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
          #entity.get
          # Omega::Client::Tracker.synchronize{
          entity.entity = miner
          entity.get_associated
          entity.start
        }
      end
    end
  end
end
