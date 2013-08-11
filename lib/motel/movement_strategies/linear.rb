# The Linear MovementStrategy model definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

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
   
   # Distance the location moves per second
   attr_accessor :speed


   # Motel::MovementStrategies::Linear initializer
   #
   # Direction vector will be normalized if not already
   #
   # @param [Hash] args hash of options to initialize the linear movement strategy with
   # @option args [Float] x coordinate of direction vector
   # @option args [Float] :dy coordinate of direction vector
   # @option args [Float] :dz z coordinate of direction vector
   # @option args [Float] :speed speed to assign to movement strategy
   # @raise [Motel::InvalidMovementStrategy] 
   # if movement strategy is not valid (see {#valid?})
   def initialize(args = {})
     attr_from_args args, :dx => 1, :dy => 0, :dz => 0, :speed => nil
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

   # Implementation of {Motel::MovementStrategy#move}
   def move(loc, elapsed_seconds)
     unless valid?
       ::RJR::Logger.warn "linear movement strategy not valid, not proceeding with move"
       return
     end

     ::RJR::Logger.debug \
       "moving location #{loc.id} via linear movement strategy #{speed} #{dx}/#{dy}/#{dz}"

     # calculate distance and update x,y,z accordingly
     distance = speed * elapsed_seconds

     loc.x += distance * dx
     loc.y += distance * dy
     loc.z += distance * dz

     # skip rotation if orientation is not set
     unless loc.orientation.any? { |lo| lo.nil? }
       rotate(loc, elapsed_seconds)
     end
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay,
                         :speed => speed,
                         :dx => dx,
                         :dy => dy,
                         :dz => dz }.merge(rotation_json)
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
