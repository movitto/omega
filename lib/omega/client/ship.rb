#!/usr/bin/ruby
# omega client ship tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'
require 'omega/client/cosmos_entity'

module Omega
  module Client
    class Ship < Entity
      def location
        Tracker.synchronize{
          @location
        }
      end

      def solar_system
        Tracker.synchronize{
          @solar_system
        }
      end

      def self.get_method
        "manufactured::get_entity"
      end

      def self.entity_type
        "Manufactured::Ship"
      end

      def closest_station
        closest_stations.first
      end

      def closest_stations
        owned_stations = Omega::Client::Station.owned_by(self.entity.user_id)

        # TODO support other systems
        owned_stations.select { |st| st.system_name == self.entity.system_name }.
                            sort   { |a,b| (self.location - a.location) <=>
                                           (self.location - b.location) }
      end

      def on_movement_of(distance, &bl)
        @location.on_movement_of(distance, &bl)
      end

      def on_event(event, &bl)
        if event == 'transferred'
          @transferred_callback = bl
          return

        elsif event == 'jumped'
          @jumped_callback = bl
          return
        end

        Tracker.synchronize{
          @@event_handlers ||= {}
          @@event_handlers[self.entity.id] ||= {}
          @@event_handlers[self.entity.id][event] ||= []
          @@event_handlers[self.entity.id][event] << bl

          unless @registered_manufactured_events
            @registered_manufactured_events = true
            RJR::Dispatcher.add_handler("manufactured::event_occurred") { |*args|
              event  = args[0]
              entity = args[event == 'mining_stopped' ? 2 : 1] 
              Omega::Client::Tracker[Omega::Client::Ship.entity_type + '-' + entity.id].entity= entity
              handlers = Tracker.synchronize { Array.new(@@event_handlers[entity.id][event]) }
              handlers.each { |cb| cb.call *args }
              nil
            }
          end
        }

        self.entity= Tracker.invoke_request 'manufactured::subscribe_to', self.entity.id, event
      end

      def move_to(args = {}, &bl)
        # TODO multisystem routes

        dst = nil

        if args[:destination] == :closest_station
          dst = closest_station
          # raise Exception if st.nil?
          args[:location] = dst.location + 10
          args.delete(:destination)
        elsif args[:destination].is_a?(Omega::Client::Station)
          dst = args[:destination]
          args[:location] = dst.location + 10
          args.delete(:destination)
        end

        if args.has_key?(:location)
          args[:x] = args[:location].x
          args[:y] = args[:location].y
          args[:z] = args[:location].z
          args.delete(:location)
        end

        loc = Motel::Location.new
        loc.update self.entity.location
        loc.x = args[:x] if args.has_key?(:x)
        loc.y = args[:y] if args.has_key?(:y)
        loc.z = args[:z] if args.has_key?(:z)
        dst = loc if dst.nil?

        entity = self
        self.on_movement_of(self.entity.location - loc){ |loc|
          bl.call entity, dst
        }if block_given?

        self.entity= Tracker.invoke_request 'manufactured::move_entity', self.entity.id, loc
        return self
      end

      def stop_moving
        self.entity= Tracker.invoke_request 'manufactured::stop_entity', self.entity.id
      end

      def jump_to(system)
        # TODO leverage system from a local registry?
        system = Omega::Client::SolarSystem.get(system) if system.is_a?(String)
        loc    = Motel::Location.new
        loc.update self.entity.location
        loc.parent_id = system.location.id
        self.entity= Tracker.invoke_request 'manufactured::move_entity', self.entity.id, loc
        self.get_associated
        @jumped_callback.call self if @jumped_callback
        return self
      end

      def transfer(quantity, args = {})
        resource_id = args[:of]
        target      = args[:to]

        entities = Tracker.invoke_request 'manufactured::transfer_resource',
                                  self.id, target.id, resource_id, quantity
        self.entity= entities.first
        @transferred_callback.call self, target, resource_id, quantity
      end

      def get_associated
        location = Omega::Client::Location.get self.entity.location.id
        solar_system   = Omega::Client::SolarSystem.get self.entity.system_name if @solar_system.nil? || @solar_system.name != self.entity.system_name
        Tracker.synchronize{
          @location = location
          @solar_system = solar_system
        }
        return self
      end
    end
  end
end
