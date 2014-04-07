# manufactured::move station in system helper
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured::RJR
  # Move station in single system
  def move_station_in_system(station, loc)
    # Verify we are processing stations here
    raise OperationError, "#{station} not a station" unless station.is_a?(Station)
  
    # When moving station, we only permit orbiting around system's star
    is_orbiting = loc.ms.is_a?(Motel::MovementStrategies::Elliptical)
    on_orbit    = is_orbiting ? loc.ms.intersects?(loc) : false
    raise OperationError, "#{station} must orbit star" unless is_orbiting
    raise OperationError,
      "station location #{station.location.coords} not on orbit" unless on_orbit
  
    # update movement strategy
    station.location.movement_strategy = loc.ms
    node.invoke('motel::update_location', station.location)
  
    # TODO update dock'd ship movement strategies?
  
    nil
  end
end
