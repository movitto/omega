# manufactured::dock, manufactured::undock
# rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'

module Manufactured::RJR

# dock ship to station
dock = proc { |ship_id, station_id|
  # retrieve/validate ship/station
  ship    = registry.entity &with_id(ship_id)
  station = registry.entity &with_id(station_id)
  raise DataNotFound, ship_id    if ship.nil?    || !ship.is_a?(Ship)
  raise DataNotFound, station_id if station.nil? || !station.is_a?(Station)
  
  # require modify on ship
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
     {:privilege => 'modify', :entity => 'manufactured_entities'}]

  # currently anyone can dock at stations
  #require_privilege :registry => user_registry, :any =>
  #  [{:privilege => 'modify', :entity => "manufactured_entity-#{station.id}"},
  #   {:privilege => 'modify', :entity => 'manufactured_entities'}]
  
  # retrieve ship/station locations from motel
  ship.location =
    node.invoke('motel::get_location', 'with_id', ship.location.id)
  station.location =
    node.invoke('motel::get_location', 'with_id', station.location.id)


  # dock registry ship
  registry.safe_exec { |entities|
    # grab ship/station from registry
    rsh = entities.find &with_id(ship.id)
    rst = entities.find &with_id(station.id)

    # update locations
    rsh.location = ship.location
    rst.location = station.location

    # ensure ship can dock at station
    raise OperationError, "cannot dock" unless rst.dockable?(rsh) &&
                                               rsh.can_dock_at?(rst)
    rsh.dock_at(rst)
  }
  
  # set ship movement strategy to stopped, update in motel
  # TODO optinally set position of ship in proximity of station
  ship.location.movement_strategy = Motel::MovementStrategies::Stopped.instance
  node.invoke('motel::update_location', ship.location)
  
  # return ship
  ship
}

# undock ship
undock = proc { |ship_id|
  # retrieve / validate ship
  ship = registry.entity &with_id(ship_id)
  raise DataNotFound, ship_id if ship.nil? || !ship.is_a?(Ship)
  
  # require modify on ship
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
     {:privilege => 'modify', :entity => 'manufactured_entities'}]
  
  # undock registry ship
  registry.safe_exec { |entities|
    # grab ship from registry
    rs = entities.find &with_id(ship.id)

    # ensure it is docked
    # TODO optionally require a station's docking clearance at some point
    raise OperationError, "not docked" unless rs.docked?
  
    # undock it
    rs.undock
  }
  
  # return ship
  ship
}

DOCK_METHODS = { :dock   => dock,
                 :undock => undock }

end # module Manufactured::RJR

def dispatch_manufactured_rjr_dock(dispatcher)
  m = Manufactured::RJR::DOCK_METHODS 
  dispatcher.handle 'manufactured::dock',   &m[:dock]
  dispatcher.handle 'manufactured::undock', &m[:undock]
end
