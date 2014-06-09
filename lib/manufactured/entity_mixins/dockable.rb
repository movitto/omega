# Manufactured Dockable Entity Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'cosmos/resource'

module Manufactured
module Entity
  module Dockable
    # {Manufactured::Station} ship is docked to, nil if not docked
    foreign_reference :docked_at

    # Initialize docking properties from args
    def docking_state_from_args(args)
      attr_from_args args, :docked_at    => nil,
                           :docked_at_id => @docked_at_id
    end

    # Return boolean indicating if docking properties are valid
    def docking_valid?
      (@docked_at.nil? || (@docked_at.is_a?(Manufactured::Station) &&
          can_dock_at?(@docked_at) && !@docked_at_id == @docked_at.id))
    end

    # Return true / false indicating if ship can dock at station
    # @param [Manufactured::Station] station station which to check if ship can dock at
    # @return [true,false] indicating if ship is in same system and within docking distance of station
    def can_dock_at?(station)
      (@location.parent_id == station.location.parent_id) &&
      (@location - station.location) <= station.docking_distance &&
      alive?
      # TODO ensure not already docked
    end

    # Return boolean indicating if ship is currently docked
    #
    # @return [true,false] indicating if ship is docked or not
    def docked?
      !self.docked_at_id.nil?
    end

    # Dock ship at the specified station
    #
    # @param [Manufactured::Station] station station to dock ship at
    def dock_at(station)
      self.docked_at = station
    end

    # Undock ship from docked station
    def undock
      # TODO check to see if station has given ship undocking clearance
      self.docked_at = nil
    end

    # Return docking attributes which are updatable
    def updatable_docking_attrs
      @updatable_docking_attrs ||= [:docked_at, :docked_at_id]
    end

    # Return docking attributes in json format
    def docking_json
      {:docked_at_id => @docked_at_id}
    end
  end # module Dockable
end # module Entity
end # module Manufactured
