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

      def self.subscribe_method
        'manufactured::subscribe_to'
      end

      def self.notification_method
        "manufactured::event_occurred"
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

        super(event, &bl)
      end

      def move_to(args = {}, &bl)
        # TODO multisystem routes

        dst = nil

        if args[:destination] == :closest_station
          dst = closest_station
          # raise Exception if st.nil?
          args[:location] = dst.location + [10,10,10]
          args.delete(:destination)

        elsif args[:destination].is_a?(Omega::Client::Station)
          dst = args[:destination]
          args[:location] = dst.location + [10,10,10]
          args.delete(:destination)
        end

        if args.has_key?(:location)
          args[:x] = args[:location].x
          args[:y] = args[:location].y
          args[:z] = args[:location].z
          args.delete(:location)
        end

        loc = Motel::Location.new
        loc.update self.location.entity
        loc.x = args[:x] if args.has_key?(:x)
        loc.y = args[:y] if args.has_key?(:y)
        loc.z = args[:z] if args.has_key?(:z)
        dst = loc if dst.nil?

        entity = self
        self.on_movement_of(self.location.entity - loc){ |loc|
          #entity.get
          # XXX this handler will be invoked before the serverside 
          # motel::on_movement callback registered by the manufactured module.
          # Thus the entity's locally tracked will not be updated by this point.
          # The client should always use the 'location' property defined on
          # this class (self.location.entity) as updated by calling get_associated,
          # instead of the location on the server side entity (self.entity.location).
          #entity.get_associated
          self.location.entity = loc
          bl.call entity, dst
        }if block_given?

        self.entity= Tracker.invoke_request 'manufactured::move_entity', self.entity.id, loc
        return self
      end

      def stop_moving
        self.entity= Tracker.invoke_request 'manufactured::stop_entity', self.entity.id
      end

      def jump_to(system)
        loc    = Motel::Location.new
        loc.update self.location.entity
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
        # needed as manufactured entity's copy of location may not always reflect
        # latest location tracked by motel:
        loc = Omega::Client::Location.get self.entity.location.id
        solar_system   = Omega::Client::SolarSystem.get self.entity.system_name if @solar_system.nil? || @solar_system.name != self.entity.system_name
        Tracker.synchronize{
          @location = loc
          @solar_system = solar_system unless solar_system.nil?
        }
        return self
      end
    end
  end
end
