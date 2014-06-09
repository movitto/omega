# Manufactured InSystem Entity Mixin
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/location'
require 'cosmos/entities/solar_system'

module Manufactured
module Entity
  # Mixin indicating entity is in a system
  module InSystem
    # [Motel::Location] of the ship in its parent solar system
    attr_reader :location

    # Set location and parent
    def location=(val)
      @location = val

      unless val.nil? || solar_system.nil? ||
             (@location.parent_id !=    # need check to skip
              solar_system.location.id) # this when updating loc
                                        # XXX y?
        @location.parent = solar_system.location
      end
    end

    alias :loc :location
    alias :loc= :location=

    # Alias movement_strategy to location.movement_strategy
    def movement_strategy
      @location.movement_strategy
    end

    # Alias movement_strategy= to location.movement_strategy=
    def movement_strategy=(val)
      @location.movement_strategy=val
    end

    # [Cosmos::SolarSystem] the ship is in
    attr_reader :solar_system

    # Set system and system id
    def solar_system=(val)
      @solar_system = val

      unless val.nil? # check loc.parent_id == val.location.id ?
        @system_id    = val.id
        @location.parent = val.location
      end
    end

    alias :parent :solar_system
    alias :parent= :solar_system=

    # [String] id of the solar system ship is in
    attr_accessor :system_id

    alias :parent_id :system_id
    alias :parent_id= :system_id=

    # Generate a new location at the default position
    def default_location
      Motel::Location.new :coordinates => [0,0,1], :orientation => [1,0,0]
    end

    # Intiailize location specified by args or default location
    def location_from_args(args)
      attr_from_args args, :location => default_location

      # set default orientation if not specified
      location.orientation = [0,0,1] if location.orientation.all? { |o| o.nil? }

      # allow location movement strategy to be specified directly through args
      location.ms = args[:movement_strategy] if args[:movement_strategy]
    end

    # Initialize system properties from args
    def system_from_args(args)
      attr_from_args args, :system_id    => nil,
                           :solar_system => nil
    end

    # Return system attributes which are updatable
    def updatable_system_attrs
      @updatable_system_attrs ||=
        [:parent_id, :parent, :system_id, :solar_system, :location]
    end

    # Return boolean indicating if location is valid
    def location_valid?
      !@location.nil? && @location.is_a?(Motel::Location)
    end

    # Return boolean indicating if system is valid
    def system_valid?
      !@system_id.nil? &&
      (@solar_system.nil? || @solar_system.is_a?(Cosmos::Entities::SolarSystem))
    end

    # Return location properties in json format
    def system_json
      {:location  => @location,
       :system_id => (@solar_system.nil? ? @system_id : @solar_system.id)}
    end
  end # module InSystem
end # module Entity
end # module Manufactured
