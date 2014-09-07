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

  # Motel::MovementStrategies::Follow initializer
  #
  # @param [Hash] args hash of options to initialize the follow
  #   movement strategy with, accepts key/value pairs corresponding
  #   to all mutable attributes
  def initialize(args = {})
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

     distance_to_cover = distance_from(loc)
     within_distance   = distance_to_cover <= @distance
     target_moving     = tracked_location.ms.class.ancestors.include?(Motel::MovementStrategies::LinearMovement)
     slower_target     = tracked_location.ms.speed < speed if target_moving
     adjust_speed      = within_distance && slower_target

     if !within_distance || target_moving
       if !facing_target?(loc)
         face_target(loc)
         rotate(loc, elapsed_seconds)
       end

       update_acceleration_from(loc)

       orig_speed   = self.speed
       self.speed   = tracked_location.ms.speed if adjust_speed

       move_linear(loc, elapsed_seconds)

       self.speed   = orig_speed if adjust_speed

     elsif !target_moving # @move_while_in_vicinity
       unless facing_target_tangent?(loc)
         # TODO replace w/ rotate_towards_target_tangent ?
         face_away_from_target(loc)
         rotate(loc, elapsed_seconds)
       end

       update_acceleration_from(loc)
       move_linear(loc, elapsed_seconds)
     end
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay}.merge(trackable_json)
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
