# manufactured::dock, manufactured::undock
# rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

manufactured_dock = proc { |ship_id, station_id|
  ship    = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first
  station = Manufactured::Registry.instance.find(:id => station_id, :type => 'Manufactured::Station').first
  
  raise Omega::DataNotFound, "manufactured ship specified by #{ship_id} not found" if ship.nil?
  raise Omega::DataNotFound, "manufactured station specified by #{station_id} not found"  if station.nil?
  
  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])
  # anyone can dock at stations?
  #Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{station.id}"},
  #                                           {:privilege => 'modify', :entity => 'manufactured_entities'}],
  #                                  :session => @headers['session_id'])
  
  Manufactured::Registry.instance.safely_run {
    # update ship / station location
    ship.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', ship.location.id))
    station.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', station.location.id))
  
    raise Omega::OperationError, "#{ship} cannot dock at #{station}" unless station.dockable?(ship)
  
    ship.dock_at(station)
  
    # set ship movement strategy to stopped
    # TODO we may want to set position of ship in proximity of station
    ship.location.movement_strategy = Motel::MovementStrategies::Stopped.instance
    @@local_node.invoke_request('motel::update_location', ship.location)
  }
  
  ship
}

manufactured_undock = proc { |ship_id|
  ship    = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first
  
  raise Omega::DataNotFound, "manufactured ship specified by #{ship_id} not found" if ship.nil?
  
  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])
  
  Manufactured::Registry.instance.safely_run {
    # TODO we may want to require a station's docking clearance at some point
    raise Omega::OperationError, "#{ship} is not docked, cannot undock" unless ship.docked?
  
    ship.undock
  }
  
  ship
}

def dispatch_resources(dispatcher)
  dispatcher.handle 'manufactured::dock',
                      &manufactured_dock
  dispatcher.handle 'manufactured::undock',
                      &manufactured_undock
end
