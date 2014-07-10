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
    def distance_from(loc)
      loc.distance_from(*tracked_location.coordinates)
    end

    # Near target
    #
    # Assumes class including this module also includes LinearMovement
    def near_target?(loc)
      distance_from(loc) <= distance
    end

    # Return orientation difference between specified location and tracked location
    def orientation_difference(loc)
      loc.orientation_difference(*tracked_location.coordinates)
    end

    # Return bool indicating if specified location is facing tracked location
    def facing_target?(loc)
     orientation_difference(loc).first.abs <= orientation_tolerance
    end

    # Rotate specified location towards target.
    #
    # Assumes class including this module also includes Rotatable
    def rotate_towards_target(loc, elapsed_seconds)
       od = orientation_difference(loc)
       init_rotation :rot_theta => rot_theta,
                     :rot_x     => od[1],
                     :rot_y     => od[2],
                     :rot_z     => od[3]
       rotate loc, elapsed_seconds if valid_rotation?
    end

    # Rotate specified location away from target
    #
    # Same assumtion as w/ rotate_towards_target above
    def rotate_away_from_target(loc, elapsed_seconds)
       od = orientation_difference(loc)
       init_rotation :rot_theta => rot_theta,
                     :rot_x     => od[1],
                     :rot_y     => od[2],
                     :rot_z     => od[3]
       self.rot_theta *= -1
       rotate loc, elapsed_seconds if valid_rotation?
       self.rot_theta *= -1
    end
  end # module TracksLocation
end # module MovementStrategies
end # module Motel
