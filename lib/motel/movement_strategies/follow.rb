# The Follow MovementStrategy model definition
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/movement_strategy'
require 'motel/mixins/movement_strategy'

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
  include LinearMovement
  include Rotatable
  include TracksLocation

  # Define if we should rotate to face target
  attr_accessor :point_to_target

  # Motel::MovementStrategies::Follow initializer
  #
  # @param [Hash] args hash of options to initialize the follow
  #   movement strategy with, accepts key/value pairs corresponding
  #   to all mutable attributes
  def initialize(args = {})
    attr_from_args args, :point_to_target => false
    linear_attrs_from_args(args)
    trackable_attrs_from_args(args)
    init_rotation(args)
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
     tracked_attrs_valid? && speed_valid?
   end

   # Implementation of {Motel::MovementStrategy#move}
   def move(loc, elapsed_seconds)
     unless valid? && has_tracked_location?
       ::RJR::Logger.warn "follow strategy not valid, not proceeding with move"
       return
     end

     unless same_system?(loc)
       ::RJR::Logger.warn "follow strategy system mismatch"
       return
     end

     ::RJR::Logger.debug "moving location #{loc.id} via follow strategy " +
                  "#{speed} #{tracked_location_id } at #{distance}"

     if @point_to_target && !facing_target?(loc)
       rotate_towards_target(loc, elapsed_seconds)
     end

     distance_to_cover = distance_from(loc)
     if distance_to_cover > @distance
       # calculate direction of tracked location
       if @point_to_target
         update_dir_from(loc)

       else
         tl = tracked_location
         dx = (tl.x - loc.x) / distance_to_cover
         dy = (tl.y - loc.y) / distance_to_cover
         dz = (tl.z - loc.z) / distance_to_cover
       end

       move_linear(loc, elapsed_seconds)

     else
       #::RJR::Logger.warn "#{location} within #{@distance} of #{tl}"
       # FIXME if target is stationary: orbit, else match speed
     end
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay      => step_delay,
                         :point_to_target => point_to_target,
                       }.merge(trackable_json)
                        .merge(rotation_json)
                        .merge(linear_json)
     }.to_json(*a)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     "follow-(#{tracked_location_id} at #{distance})"
   end
end

end # module MovementStrategies
end # module Motel
