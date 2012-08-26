# The Linear MovementStrategy model definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/movement_strategy'

module Motel
module MovementStrategies

# The Linear MovementStrategy moves a location
# in a linear manner as defined by a 
# unit direction vector and a floating point
# speed
#
# To be valid you must specify speed at a minimum
class Linear < MovementStrategy
   attr_accessor :direction_vector_x, :direction_vector_y, :direction_vector_z
   
   attr_accessor :speed

   def initialize(args = {})
     @direction_vector_x   = args[:direction_vector_x] || args[:dx] || 1
     @direction_vector_y   = args[:direction_vector_y] || args[:dy] || 0
     @direction_vector_z   = args[:direction_vector_z] || args[:dz] || 0
     @speed                = args[:speed]
     super(args)

     # normalize direction vector
     @direction_vector_x, @direction_vector_y, @direction_vector_z =
       Motel::normalize(@direction_vector_x, @direction_vector_y, @direction_vector_z)
     raise InvalidMovementStrategy.new("linear movement strategy not valid") unless valid?
   end

   def valid?
     Motel::normalized?(@direction_vector_x, @direction_vector_y, @direction_vector_z) &&
     [Float, Fixnum].include?(@speed.class) && @speed > 0
   end


   # Motel::Models::MovementStrategy::move
   def move(location, elapsed_seconds)
     unless valid?
       RJR::Logger.warn "linear movement strategy not valid, not proceeding with move"
       return
     end

     RJR::Logger.debug "moving location #{location.id} via linear movement strategy " +
                  "#{speed} #{direction_vector_x}/#{direction_vector_y}/#{direction_vector_z}"

     # calculate distance and update x,y,z accordingly
     distance = speed * elapsed_seconds

     location.x += distance * direction_vector_x
     location.y += distance * direction_vector_y
     location.z += distance * direction_vector_z
   end

   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay,
                         :speed => speed,
                         :direction_vector_x => direction_vector_x,
                         :direction_vector_y => direction_vector_y,
                         :direction_vector_z => direction_vector_z }
     }.to_json(*a)
   end

   def to_s
     s = "linear-("
     s += "#{@direction_vector_x.round_to(2)},#{@direction_vector_y.round_to(2)},#{@direction_vector_z.round_to(2)})" unless @direction_vector_x.nil? || @direction_vector_y.nil? || @direction_vector_z.nil?
     s += ")"
     s
   end
end

end # module Models
end # module Motel
