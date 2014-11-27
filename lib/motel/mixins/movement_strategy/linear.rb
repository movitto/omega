# The Linear MovementStrategy Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'

module Motel
module MovementStrategies
  module LinearMovement
    # Unit vector corresponding to the linear movement direction (velocity direction)
    attr_accessor :dx, :dy, :dz

    # Distance the location moves per second (velocity magnitude)
    attr_accessor :speed

    # Unit vector corresponding to the direction of acceleration
    attr_accessor :ax, :ay, :az

    # Magnitude of acceleration
    # TODO variable acceleration (perhaps introduce masses to locations & forces into Motel)
    attr_accessor :acceleration

    # Stop location movement automatically after this distance moved, optional
    attr_accessor :stop_distance

    # Stop location movement automatically when near specified coordinates, optional
    attr_accessor :stop_near

    # Max speed, speed after which acceleration no longer has an effect
    attr_accessor :max_speed

    # Linear direction as an array
    def dir
      [dx, dy, dz]
    end

    # Acceleration direction as an array
    def adir
      [ax, ay, az]
    end

    # Initialize linear attributes from args.
    #
    # Direction vector will be normalized if not already
    def linear_attrs_from_args(args)
      attr_from_args args, :dx => 1, :dy => 0, :dz => 0,
                           :ax => 1, :ay => 0, :az => 0,
                           :speed => nil, :acceleration => nil,
                           :stop_distance => nil,
                           :stop_near => nil,
                           :max_speed => nil

      # normalize direction & acceleration vectors
      @dx, @dy, @dz = Motel::normalize(@dx, @dy, @dz)
      @ax, @ay, @az = Motel::normalize(@ax, @ay, @az)
    end

    # Return bool indicating if linear movement attributes
    # are valid
    def linear_attrs_valid?
      Motel::normalized?(@dx, @dy, @dz) && speed_valid? &&
      (@acceleration.nil? || acceleration_valid?)
    end

    # Return boolean indicating if speed is valid
    def speed_valid?
      @speed.numeric? && @speed > 0
    end

    # Bool inidicating if acceleration is valid
    def acceleration_valid?
      @acceleration.numeric? && @acceleration > 0 &&
      Motel::normalized?(@ax, @ay, @az)
    end

    # Return bool indicating if stop distance has been exceeded
    def stop_distance_exceeded?(loc)
      !stop_distance.nil? && loc.distance_moved >= stop_distance
    end

    # Return bool indicating if stop distance will be exceeded
    # after the specified distance
    def exceeds_stop_distance?(loc, distance)
      !stop_distance.nil? && (loc.distance_moved + distance) > stop_distance
    end

    # Return distance location is from stop coordinate
    def distance_from_stop(loc)
      loc.distance_from(stop_near[1],
                        stop_near[2],
                        stop_near[3])
    end

    # Return bool indicating if loc is within specified distance of stop coordinate
    def near_stop_coordinate?(loc)
      !stop_near.nil? && distance_from_stop(loc) <= stop_near[0]
    end

    # Return bool indicating if stop coordinate will be passed after
    # the specified distance
    def exceeds_stop_coordinate?(loc, distance)
      !stop_near.nil? && (distance > distance_from_stop(loc))
    end

    # Return bool indicating if location is facing movement direction
    def facing_movement?(loc, tolerance)
      loc.orientation_difference(*dir).first <= tolerance
    end

    # Return linear attributes in json format
    def linear_json
      {:speed         => speed,
       :dx            => dx,
       :dy            => dy,
       :dz            => dz,
       :ax            => ax,
       :ay            => ay,
       :az            => az,
       :acceleration  => acceleration,
       :stop_distance => stop_distance,
       :stop_near     => stop_near,
       :max_speed     => max_speed}
    end

    # Update direction of movement from location
    def update_dir_from(loc)
      @dx = loc.orx
      @dy = loc.ory
      @dz = loc.orz
    end

    # Update acceleration of movement from location
    def update_acceleration_from(loc)
      @ax,@ay,@az = loc.is_a?(Location) ? [loc.orx, loc.ory, loc.orz] :
                                          [loc[0],  loc[1],  loc[2]]
    end

    def acceleration_component(elapsed_seconds)
      acceleration * elapsed_seconds
    end

    # Update velocity from acceleration
    def accelerate(elapsed_seconds)
      component = acceleration_component(elapsed_seconds)
      ndx = dx * speed + ax * component
      ndy = dy * speed + ay * component
      ndz = dz * speed + az * component

      @speed = Math.sqrt(ndx**2 + ndy**2 + ndz**2)
      @speed = max_speed if max_speed && speed > max_speed
      @dx, @dy, @dz = Motel::normalize(ndx, ndy, ndz)
    end

    # Move location along linear path
    def move_linear(loc, elapsed_seconds)
      accelerate(elapsed_seconds) unless acceleration.nil?

      distance = speed * elapsed_seconds

      # stop at stop distance
      distance = stop_distance - loc.distance_moved if exceeds_stop_distance?(loc, distance)

      # stop if near stop coordinate
      if near_stop_coordinate?(loc)
        distance = 0

      elsif exceeds_stop_coordinate?(loc, distance)
        distance = distance_from_stop(loc)
      end

      # update location's coordinates
      loc.x += distance * dx
      loc.y += distance * dy
      loc.z += distance * dz
      loc.distance_moved += distance
    end
  end # module LinearMovement
end # module MovementStrategies
end # module Motel
