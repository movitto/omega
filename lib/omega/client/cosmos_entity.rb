#!/usr/bin/ruby
# omega client cosmos entities tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'
require 'omega/client/location'

module Omega
  module Client
    # remote location retriever mixin
    module RemoteLocationTracker
      def location
        Omega::Client::Location.get self.location.id
      end
    end

    # remote resource sources retriever mixin
    # TODO support temporary timed cache w/ invalidation mechanism
    module RemoteResourceTracker
      def resource_sources
        Omega::Client::Tracker.invoke_request('cosmos::get_resource_sources', self.name)
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

      def get_associated
        solar_systems  = self.entity.solar_systems.collect { |ss|
          Omega::Client::SolarSystem.get ss.name
        } if @solar_systems.nil?
        Tracker.synchronize{
          @solar_systems = solar_systems if @solar_systems.nil?
        }
        return self
      end

      def get
        super if self.entity.nil?
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

      def get_associated
        self.entity.planets.each { |pl|
          pl.extend RemoteLocationTracker
        }
        self.entity.asteroids.each { |as|
          as.extend RemoteResourceTracker
        }
        return self
      end

      def get
        super if self.entity.nil?
      end
    end

  end
end
