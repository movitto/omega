# Omega Client SolarSystem Tracker
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'omega/client/entities/station'
require 'cosmos/entities/solar_system'

module Omega
  module Client
    # Omega client Cosmos::Entities::SolarSystem tracker
    class SolarSystem
      include Trackable
      include TrackEntity

      entity_type  Cosmos::Entities::SolarSystem
      get_method   "cosmos::get_entity"

      # Wrap jump gates, lookup endpoint id if missing
      def jump_gates
        @jump_gates ||=
          self.entity.jump_gates.collect { |jg|
            jg.endpoint =
              SolarSystem.cached(jg.endpoint_id) if jg.endpoint.nil?
            jg
          }
      end

      # Wrap asteroids, refresh resources
      def asteroids
        self.entity.asteroids.collect { |ast|
          ast.resources = node.invoke('cosmos::get_resources', ast.id)
          ast
        }
      end

      # Convenience utility, return manufactured entities in system
      #
      # Always issues a server side request to retrieve entities
      def entities
        # TODO convert results to omega client entity representations?
        node.invoke('manufactured::get_entities', 'under', id)
      end

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
      # @param [Hash] args used to filter system retrieved
      # @return [Cosmos::Entities::SolarSystem,nil] system with the fewest entities
      #   or nil if none found
      def self.with_fewest(args={})
        systems = []
        if(args[:type] == "Manufactured::Station")
          systems +=
            Omega::Client::Station.owned_by(args[:owned_by]).map { |s|
              [s.system_id, s.solar_system]
            }
        end

        system_map = Hash.new(0)
        systems.each { |n,s| system_map[n] += 1 }
        fewest = system_map.sort_by { |n,c| c }.first
        return nil if fewest.nil?
        fewest = fewest.first
        systems.find { |s| s.first == fewest }.last
      end

      # Conveniency utility to return the closest neighbor system with
      # entities of the specified type
      #
      # This will issue a server side request to retrieve
      # entities and systems
      #
      # @param [Hash] args used to filter systems retrieved
      # @return [Cosmos::Entities::SolarSystem,nil] closest system with no entities
      #   or nil
      def closest_neighbor_with_no(args={})
        entities = []
        entities = Omega::Client::Station.owned_by(args[:owned_by]) if(args[:type] == "Manufactured::Station")

        systems = [self]
        systems.each { |sys|
          # TODO sort jumpgates by distance from sys to endpoint
          sys.jump_gates.each { |jg|
            endpoint = Omega::Client::SolarSystem.get(jg.endpoint_id)
            if entities.find { |e| e.system_id == jg.endpoint_id }.nil?
              return endpoint
            elsif !systems.include?(jg.endpoint)
              systems << endpoint
            end
          }
        }

        return nil
      end
    end # class SolarSystem
  end # module Client
end # module Omega
