#!/usr/bin/ruby
# omega client cosmos entities tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'
require 'omega/client/location'
require 'omega/client/resource'

module Omega
  module Client
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
      attr_reader :location
      attr_reader :solar_systems

      def self.entity_type
        "Cosmos::Galaxy"
      end

      # Assuming the cosmos heirarchy doesn't change
      def self.get_all
        @@galaxies ||= super
      end

      def get_associated
        location = Omega::Client::Location.get self.entity.location.id if @location.nil?
        solar_systems  = self.entity.solar_systems.collect { |ss|
          Omega::Client::SolarSystem.get ss.name
        } if @solar_systems.nil?
        Tracker.synchronize{
          @location = location if @location.nil?
          @solar_system = solar_systems if @solar_systems.nil?
        }
        return self
      end

      def get
        super if self.entity.nil?
      end

    end

    class SolarSystem < CosmosEntity
      attr_reader :location
      attr_reader :star
      attr_reader :planets
      attr_reader :asteroids
      #attr_reader :jump_gates

      def self.entity_type
        "Cosmos::SolarSystem"
      end

      # Assuming the cosmos heirarchy doesn't change
      def self.get_all
        @@systems ||= super
      end

      def get_associated
        location = Omega::Client::Location.get self.entity.location.id if @location.nil?
        star     = Omega::Client::Star.get self.entity.star.name if @star.nil?
        planets  = self.entity.planets.collect { |pl|
          Omega::Client::Planet.get pl.name
        } if @planets.nil?
        asteroids  = self.entity.asteroids.collect { |as|
          Omega::Client::Asteroid.get as.name
        } if @asteroids.nil?
        #jump_gates  = self.entity.jump_gates.collect { |jg|
        #  Omega::Client::JumpGate.get jg.name
        #}
        Tracker.synchronize{
          @location    = location if @location.nil?
          @star        = star if @star.nil?
          @planets     = planets if @planets.nil?
          @asteroids   = asteroids if @asteroids.nil?
          #@jump_gates = jump_gates
        }
        return self
      end

      def get
        super if self.entity.nil?
      end
    end

    class Star < CosmosEntity
      attr_reader :location

      def self.entity_type
        "Cosmos::Star"
      end

      def get_associated
        location = Omega::Client::Location.get self.entity.location.id if @location.nil?
        Tracker.synchronize{
          @location = location if @location.nil?
        }
        return self
      end

      def get
        super if self.entity.nil?
      end
    end

    class Planet < CosmosEntity
      attr_reader :location
      attr_reader :moons

      def self.entity_type
        "Cosmos::Planet"
      end

      def get_associated
        location = Omega::Client::Location.get self.entity.location.id if @location.nil?
        moons    = self.entity.moons.collect { |mn|
          Omega::Client::Moon.get mn.name
        } if @moons.nil?
        Tracker.synchronize{
          @location = location if @location.nil?
          @moons = moons if @moons.nil?
        }
        return self
      end
    end

    class Moon < CosmosEntity
      attr_reader :location

      def self.entity_type
        "Cosmos::Moon"
      end

      def get_associated
        location = Omega::Client::Location.get self.entity.location.id if @location.nil?
        Tracker.synchronize{
          @location = location if @location.nil?
        }
        return self
      end

      def get
        super if self.entity.nil?
      end
    end

    class Asteroid < CosmosEntity
      attr_reader :location
      attr_reader :resource_sources

      def self.entity_type
        "Cosmos::Asteroid"
      end

      def update!
        resource_sources = Omega::Client::ResourceSource.associated_with(self.entity.name)
        Tracker.synchronize{
          @resource_sources = resource_sources
        }
        return self
      end

      def get_associated
        location  = Omega::Client::Location.get self.entity.location.id if @location.nil?
        resource_sources = Omega::Client::ResourceSource.associated_with(self.entity.name) if @resource_sources.nil?
        Tracker.synchronize{
          @location = location if @location.nil?
          @resource_sources = resource_sources if @resource_sources.nil?
        }
        return self
      end

      #def get
      #  super if self.entity.nil?
      #end
    end

    class JumpGate < CosmosEntity
      attr_reader :location

      def self.entity_type
        "Cosmos::JumpGate"
      end

      def get_associated
        location = Omega::Client::Location.get self.entity.location.id if @location.nil?
        Tracker.synchronize{
          @location = location if @location.nil?
        }
        return self
      end

      def get
        super if self.entity.nil?
      end
    end

  end
end
