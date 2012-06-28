# The Follow MovementStrategy model definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/movement_strategy'

module Motel
module MovementStrategies

# The Follow MovementStrategy follows another location
# at a specified distance
class Follow < MovementStrategy
   attr_accessor :tracked_location_id, :distance
   
   attr_accessor :speed

   def initialize(args = {})
     @tracked_location_id  = args[:tracked_location_id] if args.has_key? :tracked_location_id
     @distance             = args[:distance]            if args.has_key? :distance
     @speed                = args[:speed]               if args.has_key? :speed
     super(args)
   end


   # Motel::MovementStrategy::move
   def move(location, elapsed_seconds)
     RJR::Logger.debug "moving location #{location.id} via follow movement strategy " +
                  "#{speed} #{tracked_location_id } at #{distance}"

     # retireve location we're tracking
     # XXX don't like doing this here (should permissions be enforced for example?)
     tracked_location = Runner.instance.locations.find { |loc| loc.id == @tracked_location_id }
     distance_to_cover  = location - tracked_location

     if location.parent_id != tracked_location.parent_id
       RJR::Logger.warn "follow movement strategy not valid, not proceeding with move"

     elsif distance_to_cover <= @distance
       RJR::Logger.warn "#{location} within #{@distance} of #{tracked_location}"
       # TODO orbit the location or similar?

     else
       # calculate direction of tracked location
       direction_vector_x = (tracked_location.x - location.x) / distance_to_cover
       direction_vector_y = (tracked_location.y - location.y) / distance_to_cover
       direction_vector_z = (tracked_location.z - location.z) / distance_to_cover

       # calculate distance and update x,y,z accordingly
       distance = speed * elapsed_seconds

       location.x += distance * direction_vector_x
       location.y += distance * direction_vector_y
       location.z += distance * direction_vector_z
     end
   end

   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay,
                         :speed => speed,
                         :tracked_location_id => tracked_location_id,
                         :distance            => distance }
     }.to_json(*a)
   end

   def to_s
     "follow-(#{@tracked_location_id} at #{@distance})"
   end
end

end # module MovementStrategies
end # module Motel
