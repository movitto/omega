# The Follow MovementStrategy model definition
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/movement_strategy'
require 'rjr/common'

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

  include Rotatable

   # [Boolean] Indicates if we are close enough to the target to stop
   attr_reader :on_target

   # [String] ID of location which is being tracked
   attr_reader :tracked_location_id

   # [Motel::Location] location being tracked
   attr_reader :tracked_location

   def tracked_location_id=(val)
     @tracked_location_id = val
   end

   def tracked_location=(val)
     @tracked_location = val
     @tracked_location_id = val.id
   end

   # Distance away from tracked location to try to maintain
   attr_accessor :distance

   # Distance the location moves per second (when moving)
   attr_accessor :speed

   # Define if we should rotate to face target
   attr_accessor :point_to_target

   # Optional - Rotation speed
   attr_accessor :rotation_speed

   # Motel::MovementStrategies::Follow initializer
   #
   # @param [Hash] args hash of options to initialize the follow movement strategy with
   # @option args [Integer] :tracked_location_id,'tracked_location_id' id of the location to track
   # @option args [Integer] :tracked_location,'tracked_location' handle to the location to track
   # @option args [Float] :distance,'distance' distance away from the tracked location to try to maintain
   # @option args [Float] :speed,'speed' speed to assign to the movement strategy
   # @option args [Boolean] :point_to_target, define if we should rotate to face the target
   # @raise [Motel::InvalidMovementStrategy] if movement strategy is not valid (see {#valid?})
   def initialize(args = {})
     attr_from_args args, :distance => nil, :speed => nil,
                          :tracked_location_id     => nil,
                          :point_to_target         => false,
                          :rotation_speed          => 1
     super(args)
   end

   # Return boolean indicating if this movement strategy is valid
   #
   # Tests the various attributes of the follow movement strategy, returning 'true'
   # if everything is consistent, else false.
   #
   # Currently tests
   # * tracked location id is not nil
   # * speed is a valid numeric > 0
   # * distance is a valid numeric > 0
   def valid?
     !@tracked_location_id.nil? &&
     @speed.numeric? && @speed > 0 &&
     @distance.numeric? && @distance > 0
   end

   # Implementation of {Motel::MovementStrategy#move}
   def move(loc, elapsed_seconds)
     unless valid? && !tracked_location.nil?
       ::RJR::Logger.warn "follow movement strategy not valid, not proceeding with move"
       return
     end

     tl = tracked_location
     unless tl.parent_id == loc.parent_id
       ::RJR::Logger.warn "follow movement strategy is set to track location with different parent than the one being moved"
       return
     end

     ::RJR::Logger.debug "moving location #{loc.id} via follow movement strategy " +
                  "#{speed} #{tracked_location_id } at #{distance}"

     distance_to_cover  = loc - tl

     @on_target = distance_to_cover <= @distance

     if @on_target
       #::RJR::Logger.warn "#{location} within #{@distance} of #{tl}"
       # TODO orbit the location or similar?

     else
       # calculate direction of tracked location
       dx = (tl.x - loc.x) / distance_to_cover
       dy = (tl.y - loc.y) / distance_to_cover
       dz = (tl.z - loc.z) / distance_to_cover

       # calculate distance and update x,y,z accordingly
       distance = speed * elapsed_seconds

       loc.x += distance * dx
       loc.y += distance * dy
       loc.z += distance * dz
     end

     if @point_to_target
       # Calculate orientation difference
       # TODO separate this logic into helper
       od = loc.orientation_difference(*tl.coordinates)
       if od.first.abs > (Math::PI / 32)
         init_rotation :rot_theta =>  od[0] * @rotation_speed,
                       :rot_x     =>  od[1],
                       :rot_y     =>  od[2],
                       :rot_z     =>  od[3]
         if valid_rotation?
           rotate loc, elapsed_seconds
         end
       end
     end
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay,
                         :speed => speed,
                         :tracked_location_id => tracked_location_id,
                         :distance            => distance,
                         :point_to_target     => point_to_target,
                         :rotation_speed      => rotation_speed,
                         :on_target           => on_target
                       }.merge(rotation_json)
     }.to_json(*a)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     "follow-(#{@tracked_location_id} at #{@distance})"
   end
end

end # module MovementStrategies
end # module Motel
