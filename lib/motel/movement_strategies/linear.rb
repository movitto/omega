# The Linear MovementStrategy model definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'motel/common'
require 'motel/movement_strategy'
require 'motel/mixins/movement_strategy'

module Motel
module MovementStrategies

# The Linear MovementStrategy moves a location
# in a linear manner as defined by a
# unit direction vector and a floating point
# speed.
#
class Linear < MovementStrategy
  include LinearMovement
  include Rotatable

  # Boolean indicating movement should be in direction of
  # location's orientation
  attr_accessor :dorientation

  # Motel::MovementStrategies::Linear initializer
  #
  # @param [Hash] args hash of options to initialize the linear movement
  #   strategy with, accepts key/value pairs corresponding to all mutable
  #   attributes.
  def initialize(args = {})
    attr_from_args args, :dorientation => false
    linear_attrs_from_args(args)
    init_rotation(args)
    super(args)
  end

  # Return boolean indicating if this movement strategy is valid
  #
  # Tests the various attributes of the linear movement strategy, returning 'true'
  # if everything is consistent, else false.
  #
  # Currently tests
  # * direction vector is normalized
  # * speed is a valid numeric > 0
  # * rotation parameters
  def valid?
    linear_attrs_valid? && valid_rotation?
  end

  # Returns true if we've moved more than specified distance or
  # change_due_to_rotation? returns true
  def change?(loc)
    #change_due_to_rotation?(loc) || # TODO option to enable changing due to rotation
    stop_distance_exceeded?(loc)
  end

   # Implementation of {Motel::MovementStrategy#move}
   def move(loc, elapsed_seconds)
     unless valid?
       ::RJR::Logger.warn "linear movement strategy not valid, not proceeding with move"
       return
     end

     ::RJR::Logger.debug \
       "moving location #{loc.id} via linear movement strategy #{speed} #{dx}/#{dy}/#{dz}"

     rotate(loc, elapsed_seconds)
     update_dir_from(loc) if @dorientation
     move_linear(loc, elapsed_seconds)
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay,
                         :dorientation => dorientation }.merge(rotation_json)
                                                        .merge(linear_json)
     }.to_json(*a)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     s = "linear-("
     s += "#{@speed}->#{@dx.round_to(2)},#{@dy.round_to(2)},#{@dz.round_to(2)})"
     s += ")"
     s
   end
end # class Linear
end # module MovementStrategies
end # module Motel
