# The TracksCoordinates MovementStrategy Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'

module Motel
module MovementStrategies
  module TracksCoordinates
    # Target Coordinates Array
    attr_accessor :target

    # Max tolerance location can be from target to be at it
    attr_accessor :distance_tolerance

    # Max tolerance location orientation can be from facing target
    attr_accessor :orientation_tolerance

    # Instantiate target attributes from arguments
    def target_attrs_from_args(args)
      attr_from_args args, :target                => nil,
                           :orientation_tolerance => Math::PI / 128,
                           :distance_tolerance    => CLOSE_ENOUGH
    end

    # Return bool indicating if target attributes are valid
    def target_attrs_valid?
      target.is_a?(Array) && target.length == 3 &&
      target.all? { |t| t.numeric? }
    end

    # Return bool indicating if location is at target
    def arrived?(loc)
      loc.distance_from(*target) <= distance_tolerance
    end

    # Return distance between specified location and target
    def distance_from_target(loc)
      loc.distance_from *target
    end

    # Return direction between specified location and target
    def direction_to_target(loc)
      loc.direction_to *target
    end

    # Return direction away from target (inverted direction to target)
    def direction_away_from_target(loc)
      direction_to_target(loc).collect { |d| d * -1 }
    end

    # Return rotation between specified location and specified coords
    def rotation_to(loc, coords)
      loc.rotation_to(*coords)
    end

    # Return rotation between specified location and target
    def rotation_to_target(loc)
      rotation_to(loc, target)
    end

    # Return difference between location and specified orientation
    def orientation_difference(loc, orientation)
      loc.orientation_difference(*orientation)
    end

    def moving_towards_target?(loc)
      moving_towards?(loc, target, orientation_tolerance)
    end

    # Return bool indicating if specified location is facing specified target
    def facing?(loc, coords)
      rotation_to(loc, coords).first.abs <= orientation_tolerance
    end

    # Return bool indicating if specified location is facing target
    def facing_target?(loc)
      facing?(loc, target)
    end

    # Update movement strategy so as to rotate location towards target
    #
    # Assumes class including this module also includes Rotatable.
    def face_target(loc)
      rot = rotation_to_target(loc)
      init_rotation :rot_theta  => rot_theta,
                    :rot_x      => rot[1],
                    :rot_y      => rot[2],
                    :rot_z      => rot[3],
                    :stop_angle => rot[0].abs
      loc.angle_rotated = 0
    end

    # Update movement strategy so as to rotate location towards specified orientation
    #
    # Assumes class including this module also includes Rotatable.
    def face(loc, orientation)
      diff = orientation_difference(loc, orientation)

      init_rotation :rot_theta  => rot_theta,
                    :rot_x      => diff[1],
                    :rot_y      => diff[2],
                    :rot_z      => diff[3],
                    :stop_angle => diff[0].abs
      loc.angle_rotated = 0
    end

    # Return target attributes in json form
    def target_json
      { :target                => target,
        :orientation_tolerance => orientation_tolerance,
        :distance_tolerance    => distance_tolerance }
    end
  end # module TracksCoordinates
end # module MovementStrategies
end # module Motel
