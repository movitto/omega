# The Towards MovementStrategy model definition
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/movement_strategy'

module Motel
module MovementStrategies

# The Towards MovementStrategy moves location towards specified coordinate, optionally
# rotating it to face it. When approaching target, location will deaccelerate so as
# to stop at it
class Towards < MovementStrategy
  include LinearMovement
  include Rotatable
  include TracksCoordinates

  # Indicates if entity is arriving, used internally
  attr_accessor :arriving

  # Motel::MovementStrategies::Towards initializer
  #
  # @param [Hash] args hash of options to initialize the towards
  #   movement strategy with, accepts key/value pairs corresponding
  #   to all mutable attributes
  def initialize(args = {})
    attr_from_args args, :arriving => false

    linear_attrs_from_args args
    init_rotation(args)
    target_attrs_from_args args
    super(args)

    @distance_tolerance = 10 ** (max_speed.zeros-1)
    @stop_near          = Array.new(target).unshift 0
  end

  # Implementation of {Motel::MovementStrategy#valid?}
  def valid?
    target_attrs_valid?
  end

  # Implementation of {Motel::MovementStrategy#change?}
  def change?(loc)
    arrived?(loc)
  end

  def rotational_time
    Math::PI / rot_theta.abs
  end

  def rotational_distance
    rotational_time * speed
  end

  def linear_time
    speed/acceleration
  end

  def linear_distance
    speed * linear_time - acceleration / 2 * (linear_time ** 2)
  end

  def near_target?(loc)
    distance_from_target(loc) <= linear_distance + rotational_distance
  end

  # Implementation of {Motel::MovementStrategy#move}
  def move(loc, elapsed_seconds)
    unless valid?
      ::RJR::Logger.warn "towards strategy not valid, not proceeding with move"
      return
    end

    # slow down as we approach target
    if near_target?(loc)
      face loc, [-dx, -dy, -dz] unless @arriving
      rotate(loc, elapsed_seconds)
      @arriving = true

    else
      face_target loc
      rotate(loc, elapsed_seconds)
      @arriving = false

      # if dir is within orient_tolerance of orient, set velocity directly
      update_dir_from(loc) if facing_movement?(loc, orientation_tolerance)
    end

    orig_acceleration = @acceleration
    @acceleration = 0 unless rotation_stopped?(loc)

    update_acceleration_from(loc)
    move_linear loc, elapsed_seconds
    loc.coordinates = target if arrived?(loc)

    @acceleration = orig_acceleration
  end

  # Convert movement strategy to json representation and return it
  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       => { :step_delay => step_delay,
                        :arriving   => arriving   }.merge(target_json)
                                                   .merge(rotation_json)
                                                   .merge(linear_json)
    }.to_json(*a)
  end

  # Convert movement strategy to human readable string and return it
  def to_s
    "towards-#{target}"
  end
end # class Towards
end # module MovementStrategies
end # module Motel
