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
      attr_reader :location
      attr_reader :solar_system

      def self.get_method
        "manufactured::get_entity"
      end

      def self.entity_type
        "Manufactured::Ship"
      end

      def closest_station
        # TODO cache owned stations so we don't have to retireve evety time
        owned_stations = Omega::Client::Station.owned_by(@entity.user_id)

        # TODO support other systems
        st = owned_stations.select { |st| st.solar_system.id == @entity.solar_system.id }.
                            sort   { |a,b| (self.location - a.location) <=>
                                           (self.location - b.location) }.first
        st
      end

      def on_movement_of(distance, &bl)
        @location.on_movement_of(distance, &bl)
      end

      def on_event(event, &bl)
        @@event_handlers ||= {}
        @@event_handlers[@entity.id] ||= {}
        @@event_handlers[@entity.id][event] ||= []
        @@event_handlers[@entity.id][event] << bl

        RJR::Dispatcher.add_handler("manufactured::event_occurred") { |*args|
          event  = args[0]
          entity = args[event == 'mining_stopped' ? 2 : 1] 
          # TODO update entity on correspond client object
          Omega::Client::Tracker[Omega::Client::Ship.entity_type + '-' + entity.id].entity= entity
          @@event_handlers[entity.id][event].each { |cb| cb.call *args }
        }

        @entity = Tracker.instance.invoke_request 'omega-queue', 'manufactured::subscribe_to',
                                                  @entity.id, event
      end

      def move_to(args = {}, &bl)
        # TODO multisystem routes

        if args[:destination] == :closest_station
          st = closest_station
          # raise Exception if st.nil?
          args[:location] = st.location + 10
          args.delete(:closest_station)
        end

        if args.has_key?(:location)
          args[:x] = args[:location].x
          args[:y] = args[:location].y
          args[:z] = args[:location].z
          args.delete(:location)
        end

        loc = Motel::Location.new
        loc.update @entity.location
        loc.x = args[:x] if args.has_key?(:x)
        loc.y = args[:y] if args.has_key?(:y)
        loc.z = args[:z] if args.has_key?(:z)

        entity = self
        self.on_movement_of(@entity.location - loc){ |loc|
          bl.call entity
        }if block_given?

        @entity = Tracker.instance.invoke_request 'omega-queue', 'manufactured::move_entity',
                                                  @entity.id, loc
      end

      def jump_to(system_name)
        # TODO leverage system from a local registry?
        system = Omega::Client::SolarSystem.get(system_name)
        loc    = Motel::Location.new
        loc.update @entity.location
        loc.parent_id = system.location.id
        @entity = Tracker.instance.invoke_request 'omega-queue', 'manufactured::move_entity',
                                                  @entity.id, loc
      end

      def transfer(quantity, args = {})
        resource_id = args[:of]
        target      = args[:to]

        target = closest_station if target == :closest_station

        entities = Tracker.instance.invoke_request 'omega-queue', 'manufactured::transfer_resource',
                                                   self.id, target.id, resource_id, quantity
        @entity = entities.first
      end

      def get
        super
        @location = Omega::Client::Location.get @entity.location.id
        @solar_system   = Omega::Client::SolarSystem.get @entity.solar_system.name
      end

    end
  end
end
