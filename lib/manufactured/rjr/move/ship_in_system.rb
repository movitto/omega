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
    dx = loc.x - entity.location.x
    dy = loc.y - entity.location.y
    dz = loc.z - entity.location.z
    distance = loc - entity.location
    raise OperationError, "#{entity} at location" if distance < 1
  
    # Create linear movement strategy w/ movement trajectory
    linear =
      Motel::MovementStrategies::Linear.new :dx => dx/distance,
                                            :dy => dy/distance,
                                            :dz => dz/distance,
                                            :speed => entity.movement_speed
  
    # calculate the orientation difference
    od = entity.location.orientation_difference(*loc.coordinates)
  
    # TODO introduce point_to_target flag in Linear movement strategy
    # (similar to Follow) & use here, removing the need for the follow distinction
  
    # if we are close enough to correct orientation,
    # register linear movement strategy with entity
    if od.first.abs < (Math::PI / 32)
      entity.location.movement_strategy = linear
  
    # if we need to adjust orientation before moving,
    # register rotation movement strategy w/ entity
    else
      # create the rotation movement strategy
      rotate =
        Motel::MovementStrategies::Rotate.new \
          :rot_theta => (od[0] * entity.rotation_speed),
          :rot_x     =>  od[1],
          :rot_y     =>  od[2],
          :rot_z     =>  od[3]
  
      # register rotation w/ location, linear as next movement strategy
      entity.location.movement_strategy = rotate
      entity.location.next_movement_strategy = linear
  
      # track location rotation
      node.invoke('motel::track_rotation', entity.location.id, *od)
    end
  
    # track location movement and update location
    node.invoke('motel::track_movement', entity.location.id, distance)
    node.invoke('motel::update_location', entity.location)
    nil
  end
end
