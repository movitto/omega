#!/usr/bin/ruby
# omega client cosmos entities tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'
require 'omega/client/location'

module Omega
  module Client
    # 1 minute
    CACHE_TIMEOUT = 60

    # remote location retriever mixin
    module RemoteLocationTracker
      def enable_tracking(val)
        @tracking_enabled = val
        return self
      end

      def location
        @tracking_enabled ||= false
        @cached_location  ||= @location

        if @tracking_enabled && (@location_retrieved_timestamp.nil? ||
           (Time.now - @location_retrieved_timestamp) > CACHE_TIMEOUT)
          @cached_location = Omega::Client::Location.get @location.id
          @location_retrieved_timestamp = Time.now
        end
        @cached_location
      end
    end

    # remote resource sources retriever mixin
    module RemoteResourceTracker
      def enable_tracking(val)
        @tracking_enabled = val
        return self
      end

      def resource_sources
        @tracking_enabled  ||= false
        @cached_resources  ||= []

        if @tracking_enabled && (@resources_retrieved_timestamp.nil? ||
           (Time.now - @resources_retrieved_timestamp) > CACHE_TIMEOUT)
          @cached_resources = Omega::Client::Tracker.invoke_request('cosmos::get_resource_sources', self.name)
          @resources_retrieved_timestamp = Time.now
        end
        @cached_resources
      end
    end

    class CosmosEntity < Entity
      def self.get_method
        "cosmos::get_entity"
      end

      def entity_id
        self.entity.name
      end

      def self.entity_id_attr
        "name"
      end

    end

    class Galaxy < CosmosEntity
      attr_reader :solar_systems

      def self.entity_type
        "Cosmos::Galaxy"
      end

      # Assuming the cosmos heirarchy doesn't change
      def self.get_all
        @@galaxies ||= super
      end

      def get
        return self
      end

      def get_associated
        solar_systems  = self.entity.solar_systems.collect { |ss|
          Omega::Client::SolarSystem.new(:entity => ss).get_associated
        } if @solar_systems.nil?
        Tracker.synchronize{
          @solar_systems = solar_systems if @solar_systems.nil?
        }
        return self
      end
    end

    class SolarSystem < CosmosEntity
      def self.entity_type
        "Cosmos::SolarSystem"
      end

      # Assuming the cosmos heirarchy doesn't change
      def self.get_all
        @@systems ||= super
      end

      def get
        return self
      end

      def get_associated
        self.entity.planets.each { |pl|
          pl.extend RemoteLocationTracker
        }
        self.entity.asteroids.each { |as|
          as.extend RemoteResourceTracker
        }
        return self
      end
    end

  end
end
