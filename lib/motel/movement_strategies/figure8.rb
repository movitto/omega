# The Figure8 MovementStrategy
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/movement_strategy'
require 'motel/mixins/movement_strategy'

module Motel
module MovementStrategies

# Figure 8 movement strategy, move towards target, pass,
# continue for a distance, then rotate 180 degrees and repeat
class Figure8 < MovementStrategy
  include LinearMovement
  include Rotatable
  include TracksLocation

  # Indicates if entity is rotating, used internally
  attr_accessor :rotating

  # Indicates direction of rotation, used internally
  attr_accessor :inverted

  # Motel::MovementStrategies::Figure8 initializer
  #
  # @param [Hash] args hash of options to initialize the movement strategy with
  def initialize(args = {})
    default_args = {:orientation_tolerance => Math::PI/64}.merge(args)
    attr_from_args args, :rotating => false, :inverted => true

    linear_attrs_from_args(default_args)
    trackable_attrs_from_args(default_args)
    init_rotation(default_args)
    super(default_args)
  end

  # Return boolean indicating if this movement strategy is valid
  def valid?
    tracked_attrs_valid? && speed_valid?
    # TODO also verify rot_theta
  end

  # Implementation of {Motel::MovementStrategy#move}
  def move(loc, elapsed_seconds)
    unless valid? && has_tracked_location?
      ::RJR::Logger.warn "figure8 strategy not valid, not proceeding with move"
      return
    end

    unless same_system?(loc)
      ::RJR::Logger.warn "figure8 strategy system mismatch"
      return
    end

    ::RJR::Logger.debug "moving location #{loc.id} via figure8 strategy"

    if !near_target?(loc) && !@rotating
      @rotating = true
      @inverted = !@inverted
    end

    if @rotating && !facing_target?(loc)
      if @inverted
        rotate_away_from_target(loc, elapsed_seconds)
        @inverted = false
      else
        rotate_towards_target(loc, elapsed_seconds)
      end

    else
      @rotating = false
    end

    update_dir_from(loc)

    self.speed /= 2 if @rotating

    move_linear(loc, elapsed_seconds)

    self.speed *= 2 if @rotating
  end

  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       => { :step_delay => step_delay,
                        :rotating   => rotating,
                        :inverted   => inverted}.merge(trackable_json)
                                                .merge(rotation_json)
                                                .merge(linear_json)
    }.to_json(*a)
  end
end # class Figure8
end # module MovementStrategies
end # module Motel
