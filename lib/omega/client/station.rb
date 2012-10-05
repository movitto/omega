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
      attr_reader :location
      attr_reader :solar_system

      def self.get_method
        "manufactured::get_entity"
      end

      def self.entity_type
        "Manufactured::Station"
      end

      def construct(entity_type, args={})
        Tracker.instance.invoke_request 'manufactured::construct_entity',
                               @entity.id, entity_type, args.to_a.flatten
      end

      def jump_to(system_name)
        # TODO leverage system from a local registry?
        system = Omega::Client::SolarSystem.get(system_name)
        loc    = Motel::Location.new
        loc.update @entity.location
        loc.parent_id = system.location.id
        Tracker.instance.invoke_request 'omega-queue', 'manufactured::move_entity',
                                         @entity.id, loc
      end

      def get
        super
        @location = Omega::Client::Location.get @entity.location.id
        @solar_system   = Omega::Client::SolarSystem.get @entity.solar_system.name
      end
    end
  end
end
