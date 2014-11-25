# manufactured::move ship in system helper
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Manufactured::RJR
  # Move a ship in a single system
  def move_ship_in_system(entity, loc)
    # verify we are processing ships here, also ensure not docked
    raise OperationError, "#{entity} not ship" unless entity.is_a?(Ship)
    raise OperationError, "#{entity} docked"   unless !entity.docked?
  
    # calculate distance to move along each access
    distance = loc - entity.location
    raise OperationError, "#{entity} at location" if distance < 1

    # Create towards movement strategy
    strategy = Motel::MovementStrategies::Towards.new :target       => loc.coordinates,
                                                      :acceleration => entity.acceleration,
                                                      :max_speed    => entity.movement_speed,
                                                      :speed        => 1,
                                                      :rot_theta    => entity.rotation_speed
    stopped = Motel::MovementStrategies::Stopped.instance

    entity.location.movement_strategy      = strategy
    entity.location.next_movement_strategy = stopped

    # track location movement and update location
    node.invoke('motel::track_movement', entity.location.id, distance)
    node.invoke('motel::update_location', entity.location)
    nil
  end
end
