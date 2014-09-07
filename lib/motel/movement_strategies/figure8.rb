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

  # Indicates if entity is evading, movng away for target to plot another route
  attr_accessor :evading

  # Motel::MovementStrategies::Figure8 initializer
  #
  # @param [Hash] args hash of options to initialize the movement strategy with
  def initialize(args = {})
    default_args = {:orientation_tolerance => Math::PI/64}.merge(args)
    attr_from_args args, :evading  => false

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

    within_distance = near_target?(loc)
    near_target     = near_target?(loc, distance / 5)
    facing_target   = facing_target?(loc)

    if !within_distance
      # pick initial trajectory to begin approach
      if @evading
        ::RJR::Logger.debug "location #{loc.id} approaching target via figure8 strategy"
        face_target(loc)
      end

      # evading phase is over
      @evading = false

    else
      if near_target
        # pick initial trajectory to begin evasion
        unless @evading
          ::RJR::Logger.debug "location #{loc.id} evading target via figure8 strategy"
          face_away_from_target(loc)
        end

        # evading phase has begun
        @evading = true
      end

      # when within tracking distance and not evading, always face target
      face_target(loc) if(!@evading && !facing_target)
    end

    # rotate location according to movement strategy
    rotate loc, elapsed_seconds if valid_rotation?

    # update acceleration direction from location trajectory
    update_acceleration_from(loc)

    # pause acceleration if we're reseting approach trajectory
    pause_acceleration = !within_distance && !facing_target
    orig_acceleration  = @acceleration
    @acceleration = nil if pause_acceleration

    move_linear(loc, elapsed_seconds)

    @acceleration = orig_acceleration if pause_acceleration
  end

  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       => { :step_delay => step_delay,
                        :evading    => evading}.merge(trackable_json)
                                               .merge(rotation_json)
                                               .merge(linear_json)
    }.to_json(*a)
  end
end # class Figure8
end # module MovementStrategies
end # module Motel
