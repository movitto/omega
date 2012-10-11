#!/usr/bin/ruby
# omega client station tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'
require 'omega/client/cosmos_entity'

module Omega
  module Client
    class Station < Entity
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
        "Manufactured::Station"
      end

      # TODO also delegate manfuactured::subscribe to events like
      # the ship client
      def on_event(event, &bl)
        if event == 'jumped'
          @jumped_callback = bl
          return
        end
      end


      def construct(entity_type, args={})
        Tracker.invoke_request 'manufactured::construct_entity',
                      self.entity.id, entity_type, *(args.to_a.flatten)
      end

      def jump_to(system)
        # TODO leverage system from a local registry?
        system = Omega::Client::SolarSystem.get(system) if system.is_a?(String)
        loc    = Motel::Location.new
        loc.update self.location.entity
        loc.parent_id = system.location.id
        self.entity= Tracker.invoke_request 'manufactured::move_entity', self.entity.id, loc
        self.get_associated
        @jumped_callback.call self if @jumped_callback
        return self
      end

      def get_associated
        # see comment about location in omega/client/ship::get_associated
        location = Omega::Client::Location.get self.entity.location.id
        solar_system   = Omega::Client::SolarSystem.get self.entity.system_name if @solar_system.nil? || @solar_system.name != self.entity.system_name
        Tracker.synchronize{
          @location = location
          @solar_system = solar_system unless solar_system.nil?
        }
        return self
      end
    end
  end
end
