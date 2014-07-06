# The Linear MovementStrategy Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'

module Motel
module MovementStrategies
  module LinearMovement
    # Unit vector corresponding to the linear movement direction
    attr_accessor :dx, :dy, :dz

    # Distance the location moves per second
    attr_accessor :speed

    # Stop location movement automatically after this distance moved, optional
    attr_accessor :stop_distance

    # Initialize linear attributes from args.
    #
    # Direction vector will be normalized if not already
    def linear_attrs_from_args(args)
      attr_from_args args, :dx => 1, :dy => 0, :dz => 0,
                           :speed => nil,
                           :stop_distance => nil

      # normalize direction vector
      @dx, @dy, @dz = Motel::normalize(@dx, @dy, @dz)
    end

    # Return bool indicating if linear movement attributes
    # are valid
    def linear_attrs_valid?
      Motel::normalized?(@dx, @dy, @dz) && speed_valid?
    end

    # Return boolean indicating if speed is valid
    def speed_valid?
      @speed.numeric? && @speed > 0
    end

    # Return bool indicating if stop distance has been exceeded
    def stop_distance_exceeded?(loc)
      !stop_distance.nil? && loc.distance_moved >= stop_distance
    end

    # Return linear attributes in json format
    def linear_json
      {:speed         => speed,
       :dx            => dx,
       :dy            => dy,
       :dz            => dz,
       :stop_distance => stop_distance}
    end

    # Update direction of movement from location if appropriate
    def update_dir_from(loc)
      @dx = loc.orx
      @dy = loc.ory
      @dz = loc.orz
    end

    # Move location along linear path
    def move_linear(loc, elapsed_seconds)
      distance     = speed * elapsed_seconds

      # stop at stop distance
      exceeds_stop = !stop_distance.nil? &&
                     (loc.distance_moved + distance) > stop_distance
      distance     = (stop_distance - loc.distance_moved) if exceeds_stop

      # update location's coordinates
      loc.x += distance * dx
      loc.y += distance * dy
      loc.z += distance * dz
      loc.distance_moved += distance
    end
  end # module LinearMovement
end # module MovementStrategies
end # module Motel
