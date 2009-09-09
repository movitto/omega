# The Linear MovementStrategy model definition
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel/common'
require 'motel/models/movement_strategy'

module Motel
module Models

# The Linear MovementStrategy moves a location
# in a linear manner as defined by a 
# unit direction vector and a floating point
# speed
class Linear < MovementStrategy

   # Linear MovementStrategy must specify x,y,z components of 
   # a unit direction vector
   validates_presence_of [:direction_vector_x, 
                          :direction_vector_y, 
                          :direction_vector_z]

   # make sure the unit direction vector is normal
   before_validation :normalize_direction_vector
   def normalize_direction_vector
      dx, dy, dz =
         normalize(direction_vector_x, direction_vector_y, direction_vector_z)
      self.direction_vector_x, self.direction_vector_y, self.direction_vector_z = dx, dy, dz
   end


   # Linear MovementStrategy must specify the speed
   # at which the location is moving
   validates_presence_of :speed
   validates_numericality_of :speed,
      :greater_than_or_equal_to => 0

   # Motel::Models::MovementStrategy::move
   def move(location, elapsed_seconds)
     unless valid?
       $logger.warn "linear movement strategy not valid, not proceeding with move"
       return
     end

     $logger.debug "moving location #{location.to_s} via linear movement strategy"

     # calculate distance and update x,y,z accordingly
     distance = speed * elapsed_seconds

     location.x += distance * direction_vector_x
     location.y += distance * direction_vector_y
     location.z += distance * direction_vector_z

     $logger.debug "moved location #{location} via linear movement strategy"
   end

   # convert non-nil linear movement strategy attributes to a hash
   def to_h
     result = {}
     result[:speed] = speed unless speed.nil?
     result[:direction_vector_x] = direction_vector_x unless direction_vector_x.nil?
     result[:direction_vector_y] = direction_vector_y unless direction_vector_y.nil?
     result[:direction_vector_z] = direction_vector_z unless direction_vector_z.nil?
     return result
   end

   # convert linear movement strategy to a string
   def to_s
     super + "; speed: #{speed}; direction_vector_x:#{direction_vector_x}; " + 
             "direction_vector_y:#{direction_vector_y}; direction_vector_z:#{direction_vector_z}"
   end
end

end # module Models
end # module Motel
