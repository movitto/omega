# The Follow MovementStrategy model definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/movement_strategy'

module Motel
module MovementStrategies

# The Follow MovementStrategy follows another location
# at a specified distance.
#
# If location is at this distance, it will idle in the same location.
# If nearer / further away this will continously calculate the direction
# vector to the nearest point the specified distance away from the tracked
# location and move in a linear fashion to it.
#
# To be valid, specify tracked_location_id, distance, and speed
class Follow < MovementStrategy
   # [Motel::Location] ID of and handle to location which is being tracked
   attr_accessor :tracked_location_id, :tracked_location

   # Distance away from tracked location to try to maintain
   attr_accessor :distance
   
   # Distance the location moves per second (when moving)
   attr_accessor :speed

   # Motel::MovementStrategies::Follow initializer
   #
   # @param [Hash] args hash of options to initialize the follow movement strategy with
   # @option args [Integer] :tracked_location_id,'tracked_location_id' id of the location to track
   # @option args [Float] :distance,'distance' distance away from the tracked location to try to maintain
   # @option args [Float] :speed,'speed' speed to assign to the movement strategy
   # @raise [Motel::InvalidMovementStrategy] if movement strategy is not valid (see {#valid?})
   def initialize(args = {})
     @tracked_location_id  = args[:tracked_location_id] || args['tracked_location_id']
     @distance             = args[:distance]            || args['distance']
     @speed                = args[:speed]               || args['speed']

     # retireve location we're tracking
     # XXX don't like doing this here (should permissions be enforced for example?)
     @tracked_location = Runner.instance.locations.find { |loc| loc.id == @tracked_location_id }

     super(args)

     raise InvalidMovementStrategy.new("follow movement strategy not valid") unless valid?
   end

   # Return boolean indicating if this movement strategy is valid
   #
   # Tests the various attributes of the follow movement strategy, returning 'true'
   # if everything is consistent, else false.
   #
   # Currently tests
   # * tracked location id is not nil
   # * speed is a valid float/fixnum > 0
   # * distance is a valid float/fixnum > 0
   def valid?
     !@tracked_location_id.nil? &&
     [Float, Fixnum].include?(@speed.class) && @speed > 0 &&
     [Float, Fixnum].include?(@distance.class) && @distance > 0
   end

   # Implementation of {Motel::MovementStrategy#move}
   def move(location, elapsed_seconds)
     unless valid? && !tracked_location.nil?
       RJR::Logger.warn "follow movement strategy not valid, not proceeding with move"
       return
     end

     tl = tracked_location
     unless tl.parent_id == location.parent_id
       RJR::Logger.warn "follow movement strategy is set to track location with different parent than the one being moved"
       return
     end

     RJR::Logger.debug "moving location #{location.id} via follow movement strategy " +
                  "#{speed} #{tracked_location_id } at #{distance}"

     distance_to_cover  = location - tl

     if location.parent_id != tl.parent_id
       RJR::Logger.warn "follow movement strategy not valid, not proceeding with move"

     elsif distance_to_cover <= @distance
       RJR::Logger.warn "#{location} within #{@distance} of #{tl}"
       # TODO orbit the location or similar?

     else
       # calculate direction of tracked location
       direction_vector_x = (tl.x - location.x) / distance_to_cover
       direction_vector_y = (tl.y - location.y) / distance_to_cover
       direction_vector_z = (tl.z - location.z) / distance_to_cover

       # calculate distance and update x,y,z accordingly
       distance = speed * elapsed_seconds

       location.x += distance * direction_vector_x
       location.y += distance * direction_vector_y
       location.z += distance * direction_vector_z
     end
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay,
                         :speed => speed,
                         :tracked_location_id => tracked_location_id,
                         :distance            => distance }
     }.to_json(*a)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     "follow-(#{@tracked_location_id} at #{@distance})"
   end
end

end # module MovementStrategies
end # module Motel
