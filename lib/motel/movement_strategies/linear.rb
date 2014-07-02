# The Linear MovementStrategy model definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'motel/common'
require 'motel/movement_strategy'
require 'motel/movement_strategies/rotate'

module Motel
module MovementStrategies

# The Linear MovementStrategy moves a location
# in a linear manner as defined by a
# unit direction vector and a floating point
# speed.
#
class Linear < MovementStrategy

  # Supports location rotation as it moves along the linear path
  include Rotatable

   # Unit vector corresponding to the linear movement direction
   attr_accessor :dx, :dy, :dz

   # Boolean indicating movement should be in direction of
   # location's orientation
   attr_accessor :dorientation

   # Distance the location moves per second
   attr_accessor :speed

   # Stop location movement automatically after this distance moved, optional
   attr_accessor :stop_distance

   # Motel::MovementStrategies::Linear initializer
   #
   # Direction vector will be normalized if not already
   #
   # @param [Hash] args hash of options to initialize the linear movement strategy with
   # @option args [Float] x coordinate of direction vector
   # @option args [Float] :dy coordinate of direction vector
   # @option args [Float] :dz z coordinate of direction vector
   # @option args [Float] :speed speed to assign to movement strategy
   def initialize(args = {})
     attr_from_args args, :dx => 1, :dy => 0, :dz => 0, :speed => nil,
                          :stop_distance => nil,
                          :dorientation => false
     init_rotation(args)
     super(args)

     # normalize direction vector
     @dx, @dy, @dz = Motel::normalize(@dx, @dy, @dz)
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
     Motel::normalized?(@dx, @dy, @dz) &&
     @speed.numeric? && @speed > 0 && valid_rotation?
   end

   # Returns true if we've moved more than specified distance or
   # change_due_to_rotation? returns true
   def change?(loc)
     #change_due_to_rotation?(loc) || # TODO option to enable changing due to rotation
     (!stop_distance.nil? && loc.distance_moved >= stop_distance)
   end

   # Update direction of movement from location if appropriate
   def update_dir_from(loc)
     return unless @dorientation
     @dx = loc.orx
     @dy = loc.ory
     @dz = loc.orz
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
     update_dir_from(loc)

     distance     = speed * elapsed_seconds
     exceeds_stop = (loc.distance_moved + distance) > stop_distance
     distance     = (stop_distance - loc.distance_moved) if exceeds_stop

     loc.x += distance * dx
     loc.y += distance * dy
     loc.z += distance * dz
     loc.distance_moved += distance
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay,
                         :speed => speed,
                         :stop_distance => stop_distance,
                         :dx => dx,
                         :dy => dy,
                         :dz => dz,
                         :dorientation => dorientation }.merge(rotation_json)
     }.to_json(*a)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     s = "linear-("
     s += "#{@speed}->#{@dx.round_to(2)},#{@dy.round_to(2)},#{@dz.round_to(2)})"
     s += ")"
     s
   end
end

end # module MovementStrategies
end # module Motel
