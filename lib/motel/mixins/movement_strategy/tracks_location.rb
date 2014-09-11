# The TracksLocation MovementStrategy Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'

module Motel
module MovementStrategies
  module TracksLocation
    # [String] ID of location which is being tracked
    attr_reader :tracked_location_id

    # [Motel::Location] location being tracked
    attr_reader :tracked_location

    # Convenience wrapper around tracked_location
    def has_tracked_location?
      !tracked_location.nil?
    end

    def tracked_location_id=(val)
      @tracked_location_id = val
    end

    def tracked_location=(val)
      @tracked_location = val
      @tracked_location_id = val.id
    end

    # Distance away from tracked location to try to maintain
    attr_accessor :distance

    # Max tolerance location orientation can be from facing target
    attr_accessor :orientation_tolerance

    # Instantiate tracked attributes from arguments
    def trackable_attrs_from_args(args)
      attr_from_args args, :distance              => nil,
                           :tracked_location_id   => nil,
                           :orientation_tolerance => Math::PI / 32
    end

    # Return bool indicating if tracked attributes are valid
    def tracked_attrs_valid?
     !@tracked_location_id.nil? &&
     @distance.numeric? && @distance > 0
    end

    # Return trackable attributes in json form
    def trackable_json
      {:tracked_location_id => tracked_location_id,
       :distance            => distance}
    end

    # Return boolean indicating if specified location is in same system
    # as tracked location
    def same_system?(loc)
      tracked_location.parent_id == loc.parent_id
    end

    # Return distance between location and tracked location
    def distance_from(loc, target = nil)
      loc.distance_from(*(target ? target : tracked_location.coordinates))
    end

    # Bool indicating if location is within distance of target.
    # Distance may be specified or will default to movement
    # strategy distance
    #
    # Assumes class including this module also includes LinearMovement
    def near_target?(loc, dist = distance)
      distance_from(loc) <= dist
    end

    # Return rotation between specified location and tracked location
    def rotation_to_target(loc)
      loc.rotation_to(*tracked_location.coordinates)
    end

    # Return rotation between specified location and tracked location
    def rotation_to(loc, target)
      loc.rotation_to(*target)
    end

    # Return bool indicating if specified location is facing tracked location
    def facing_target?(loc)
     rotation_to_target(loc).first.abs <= orientation_tolerance
    end

    # Return bool indicating if specified location if facing direction
    # tangential to target
    def facing_target_tangent?(loc)
      (rotation_to_target(loc).first.abs - Math::PI / 2).abs <=  orientation_tolerance
    end

    # Update movement strategy so as to rotate location towards target
    #
    # Assumes class including this module also includes Rotatable.
    def face_target(loc, target = nil)
       rot = target.nil? ? rotation_to_target(loc) : rotation_to(loc, target)
       init_rotation :rot_theta  => rot_theta,
                     :rot_x      => rot[1],
                     :rot_y      => rot[2],
                     :rot_z      => rot[3],
                     :stop_angle => rot[0].abs
       loc.angle_rotated = 0
    end

    # Update movement strategy so as to rotate location away from target
    #
    # Assumes class including this module also includes Rotatable.
    def face_away_from_target(loc)
       rot = rotation_to_target(loc)

       angle = rot[0]
       max_angle = Math::PI/4
       if(angle > max_angle)
         angle = angle - max_angle
       else
         angle = max_angle - angle
       end

       loc.angle_rotated = 0
       init_rotation :rot_theta  => rot_theta,
                     :rot_x      => rot[1],
                     :rot_y      => rot[2],
                     :rot_z      => rot[3],
                     :stop_angle => angle.abs
    end
  end # module TracksLocation
end # module MovementStrategies
end # module Motel
