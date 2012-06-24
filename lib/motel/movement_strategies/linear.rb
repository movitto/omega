# The Linear MovementStrategy model definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/movement_strategy'

module Motel
module MovementStrategies

# The Linear MovementStrategy moves a location
# in a linear manner as defined by a 
# unit direction vector and a floating point
# speed
class Linear < MovementStrategy
   attr_accessor :direction_vector_x, :direction_vector_y, :direction_vector_z
   
   attr_accessor :speed

   def initialize(args = {})
     @direction_vector_x   = args[:direction_vector_x] if args.has_key? :direction_vector_x
     @direction_vector_y   = args[:direction_vector_y] if args.has_key? :direction_vector_y
     @direction_vector_z   = args[:direction_vector_z] if args.has_key? :direction_vector_z
     @speed                = args[:speed] if args.has_key? :speed
     super(args)

     # normalize direction vector
     @direction_vector_x, @direction_vector_y, @direction_vector_z =
       Motel::normalize(@direction_vector_x, @direction_vector_y, @direction_vector_z)
   end


   # Motel::Models::MovementStrategy::move
   def move(location, elapsed_seconds)
     #unless valid?
     #  Logger.warn "linear movement strategy not valid, not proceeding with move"
     #  return
     #end

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
     "linear-(#{@direction_vector_x.round_to(2)},#{@direction_vector_y.round_to(2)},#{@direction_vector_z.round_to(2)})"
   end
end

end # module Models
end # module Motel
