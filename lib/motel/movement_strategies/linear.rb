# The Linear MovementStrategy model definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO extract rotation bits into a seperate mixinable module

require 'motel/common'
require 'motel/movement_strategy'

module Motel
module MovementStrategies

# The Linear MovementStrategy moves a location
# in a linear manner as defined by a 
# unit direction vector and a floating point
# speed.
#
# Also supports location rotation as it moved along the linear path
class Linear < MovementStrategy
   # Unit vector corresponding to the linear movement direction
   attr_accessor :direction_vector_x, :direction_vector_y, :direction_vector_z
   
   # Distance the location moves per second
   attr_accessor :speed

   # Angular speed which location is rotating
   attr_accessor :dtheta, :dphi

   # Motel::MovementStrategies::Linear initializer
   #
   # Direction vector will be normalized if not already
   #
   # @param [Hash] args hash of options to initialize the linear movement strategy with
   # @option args [Float] :direction_vector_x,:dx x coordinate of direction vector
   # @option args [Float] :direction_vector_y,:dy y coordinate of direction vector
   # @option args [Float] :direction_vector_z,:dz z coordinate of direction vector
   # @option args [Float] :speed speed to assign to movement strategy
   # @raise [Motel::InvalidMovementStrategy] if movement strategy is not valid (see {#valid?})
   def initialize(args = {})
     @direction_vector_x   = args[:direction_vector_x] || args['direction_vector_x'] || args[:dx] || args['dx'] || 1
     @direction_vector_y   = args[:direction_vector_y] || args['direction_vector_y'] || args[:dy] || args['dy'] || 0
     @direction_vector_z   = args[:direction_vector_z] || args['direction_vector_z'] || args[:dz] || args['dz'] || 0
     @speed                = args[:speed] || args['speed']
     @dtheta               = args[:dtheta]|| args['dtheta'] || 0
     @dphi                 = args[:dphi]  || args['dphi']   || 0
     super(args)

     # normalize direction vector
     @direction_vector_x, @direction_vector_y, @direction_vector_z =
       Motel::normalize(@direction_vector_x, @direction_vector_y, @direction_vector_z)
     raise InvalidMovementStrategy.new("linear movement strategy not valid") unless valid?
   end

   # Return boolean indicating if this movement strategy is valid
   #
   # Tests the various attributes of the linear movement strategy, returning 'true'
   # if everything is consistent, else false.
   #
   # Currently tests
   # * direction vector is normalized
   # * speed is a valid float/fixnum > 0
   def valid?
     Motel::normalized?(@direction_vector_x, @direction_vector_y, @direction_vector_z)             &&
                      [Float, Fixnum].include?(@speed.class)  && @speed > 0                        &&
     (@dtheta.nil? || ([Float, Fixnum].include?(@dtheta.class) && @dtheta >= 0 && @dtheta < 6.28)) &&
     (@dphi.nil?   || ([Float, Fixnum].include?(@dphi.class)   && @dphi   >= 0 && @dphi   < 6.28))
   end


   # Implementation of {Motel::MovementStrategy#move}
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

     # update location's orientation
     loct, locp = location.spherical_orientation
     unless loct.nil? || locp.nil?
       loct += dtheta * elapsed_seconds
       locp += dphi   * elapsed_seconds
       location.orientation_x,location.orientation_y,location.orientation_z =
         Motel.from_spherical(loct, locp, 1)
     end
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay,
                         :speed => speed,
                         :dtheta => dtheta, :dphi => dphi,
                         :direction_vector_x => direction_vector_x,
                         :direction_vector_y => direction_vector_y,
                         :direction_vector_z => direction_vector_z }
     }.to_json(*a)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     s = "linear-("
     s += "#{@direction_vector_x.round_to(2)},#{@direction_vector_y.round_to(2)},#{@direction_vector_z.round_to(2)})" unless @direction_vector_x.nil? || @direction_vector_y.nil? || @direction_vector_z.nil?
     s += ")"
     s
   end
end

end # module MovementStrategies
end # module Motel
