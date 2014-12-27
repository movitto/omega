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

  # Override TracksCoordinates#target= to set stop_near
  def target=(val)
    @target = val
    @stop_near = Array.new(val).unshift 1 unless val.nil?
    @target
  end

  # Override LinearMovement#max_speed= to set distance_tolerance
  def max_speed=(val)
    @max_speed = val
    @distance_tolerance = 10 ** (val.digits-1) unless val.nil?
    @max_speed
  end

  # Motel::MovementStrategies::Towards initializer
  #
  # @param [Hash] args hash of options to initialize the towards
  #   movement strategy with, accepts key/value pairs corresponding
  #   to all mutable attributes
  def initialize(args = {})
    linear_attrs_from_args args
    init_rotation(args)
    target_attrs_from_args args
    super(args)
  end

  # Implementation of {Motel::MovementStrategy#valid?}
  def valid?
    target_attrs_valid?
  end

  # Implementation of {Motel::MovementStrategy#change?}
  def change?(loc)
    arrived?(loc)
  end

  def near_distance
    speed.to_f ** 2 / (2 * acceleration)
  end

  def near_target?(loc)
    distance_from_target(loc) <= near_distance
  end

  def state(loc)
    near_target?(loc) ? "near" : "far"
  end

  # Implementation of {Motel::MovementStrategy#move}
  def move(loc, elapsed_seconds)
    unless valid?
      ::RJR::Logger.warn "towards strategy not valid, not proceeding with move"
      return
    end

    # always face target
    face_target(loc)
    rotate(loc, elapsed_seconds)

    # if near, deaccelerate, else accelerate
    near_target?(loc) ?
      update_acceleration_from(loc.inverse_orientation) :
      update_acceleration_from(loc.orientation)

    # XXX align movement if within tolerance (else will never be 100% aligned)
    update_dir_from(loc) if facing_movement?(loc, orientation_tolerance)

    # disable acceleration if rotating
    oa = acceleration
    @acceleration = nil unless rotation_stopped?(loc)

    # move towards target
    move_linear(loc, elapsed_seconds)

    # restore acceleration
    @acceleration = oa
  end

  # Convert movement strategy to json representation and return it
  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       => { :step_delay => step_delay}.merge(target_json)
                                                  .merge(rotation_json)
                                                  .merge(linear_json)
    }.to_json(*a)
  end

  # Convert movement strategy to human readable string and return it
  def to_s
    "towards-#{target.collect { |t| t.round_to(4)}}"
  end
end # class Towards
end # module MovementStrategies
end # module Motel
