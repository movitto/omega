# manufactured::move ship in system helper
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Manufactured::RJR
  # Move a ship in a single system
  def move_ship_in_system(entity, loc)
    # TODO may want to incorporate fuel into this at some point
  
    # verify we are processing ships here, also ensure not docked
    raise OperationError, "#{entity} not ship" unless entity.is_a?(Ship)
    raise OperationError, "#{entity} docked"   unless !entity.docked?
  
    # calculate distance to move along each access
    distance = loc - entity.location
    raise OperationError, "#{entity} at location" if distance < 1

    # calculate the orientation difference
    od = entity.location.orientation_difference(*loc.coordinates)

    # Create linear movement strategy w/ movement trajectory
    stopped = Motel::MovementStrategies::Stopped.instance
    linear  = Motel::MovementStrategies::Linear.new :dorientation  => true,
                                                    :stop_distance => distance,
                                                    :speed         => entity.movement_speed
    entity.location.movement_strategy      = linear
    entity.location.next_movement_strategy = stopped

    if od.first.abs > (Math::PI / 32)
      entity.location.ms.rot_theta  = od[0] * entity.rotation_speed
      entity.location.ms.rot_x      = od[1]
      entity.location.ms.rot_y      = od[2]
      entity.location.ms.rot_z      = od[3]
      entity.location.ms.stop_angle = od[0]

      node.invoke('motel::track_rotation', entity.location.id, *od)
    end
  
    # track location movement and update location
    node.invoke('motel::track_movement', entity.location.id, distance)
    node.invoke('motel::update_location', entity.location)
    nil
  end
end
