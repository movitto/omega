#!/usr/bin/ruby
# omega client cosmos entities tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client2/mixins'
require 'cosmos'

module Omega
  module Client
    # Omega client Cosmos::Galaxy tracker
    class Galaxy
      include RemotelyTrackable

      entity_type  Cosmos::Galaxy
      get_method   "cosmos::get_entity"
    end

    # Omega client Cosmos::SolarSystem tracker
    class SolarSystem
      include RemotelyTrackable

      entity_type  Cosmos::SolarSystem
      get_method   "cosmos::get_entity"

      # Conveniency utility to return the system containing
      # the fewest entities of the specified type
      #
      # This will issue a server side request to retrieve
      # entities (and systems they are in via the Client::Node
      # automatically).
      #
      # *note* this will only consider systems w/ entities, systems
      # w/ none of the specified entity will not be returned
      #
      # @param [String] entity_type type of entity to retrieve,
      #   currently only accepts Manufactured::Station
      # @return [Cosmos::SolarSystem,nil] system with the fewest entities
      #   or nil if none found
      def self.with_fewest(entity_type)
        systems = []
        if(entity_type == "Manufactured::Station")
          systems +=
            Station.owned_by(Node.user.id).map { |s|
              [s.system_name, s.solar_system]
            }
        end

        system_map = Hash.new(0)
        systems.each { |n,s| system_map[n] += 1 }
        fewest = system_map.sort_by { |n,c| c }.first
        return nil if fewest.nil?
        fewest = fewest.first
        systems.find { |s| s.first == fewest }.last
      end
    end
  end
end
