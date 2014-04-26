# Manufactured HasDocks Entity Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/constraints'

module Manufactured
module Entity
  module HasDocks
    include Omega::ConstrainedAttributes

    def self.included(base)
      base.inherit_constraints self
    end

    # TODO number of ships which may be docked to the station at any one time
    #constrained_attr :ports

    # Max distance a ship can be from station to dock with it
    constrained_attr :docking_distance

    # Return true / false indicating station permits specified ship to dock
    #
    # @param [Manufactured::Ship] ship ship which to give or deny docking clearance
    # @return [true,false] indicating if ship is allowed to dock at station
    def dockable?(ship)
      (ship.location.parent_id == location.parent_id) &&
      (ship.location - location) <= docking_distance &&
      !ship.docked?
    end

    # Return dock attributes in json format
    def docks_json
      {:docking_distance => @docking_distance}
    end
  end # module HasDocks
end # module Entity
end # module Manufactured
