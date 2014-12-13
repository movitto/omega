# The Follow MovementStrategy model definition
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/movement_strategy'
require 'motel/mixins/movement_strategy'
require 'motel/mixins/elliptical'

require 'rjr/common'

module Motel
module MovementStrategies

# The Follow MovementStrategy follows another location
# at a specified distance.
#
# Location will move to vicinity of tracked location, if tracked location
# is within specified distance, location will orbit it. If tracked location
# is moving, location will follow, adjusting speed if necessary.
class Follow < MovementStrategy
  include LinearMovement
  include Rotatable
  include TracksLocation

  include EllipticalAxis
  include EllipticalPath
  include EllipticalMovement

  # Current movement target coordinates, used internally
  attr_accessor :target

  # Initialize the ellptical orbit from the specified movement
  # strategy properties
  def init_orbit
    axis_from_args :dmajx =>  MAJOR_CARTESIAN_AXIS[0],
                   :dmajy =>  MAJOR_CARTESIAN_AXIS[1],
                   :dmajz =>  MAJOR_CARTESIAN_AXIS[2],
                   :dminx =>  CARTESIAN_NORMAL_VECTOR[0],
                   :dminy =>  CARTESIAN_NORMAL_VECTOR[1],
                   :dminz => -CARTESIAN_NORMAL_VECTOR[2]

    # circular orbit at specified distance (since e = 0 ; a == p)
    path_from_args :e => 0, :p => @distance
  end

  # Override Elliptical Path Center to orbit tracked location
  def center
    @tracked_location ? @tracked_location.coordinates : [0, 0, 0]
  end

  # Motel::MovementStrategies::Follow initializer
  #
  # @param [Hash] args hash of options to initialize the follow
  #   movement strategy with, accepts key/value pairs corresponding
  #   to all mutable attributes
  def initialize(args = {})
    default_args = {:orientation_tolerance => Math::PI/32}.merge(args)
    attr_from_args args, :target => nil

    linear_attrs_from_args(default_args)
    trackable_attrs_from_args(default_args)
    init_rotation(default_args)
    init_orbit

    super(default_args)
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

     within_distance   = distance_from(loc) <= @distance
     target_moving     = tracked_location.ms.class.ancestors.include?(LinearMovement)

     if target_moving
       slower_target   = tracked_location.ms.speed < speed
       reduce_speed    = within_distance && slower_target

       # TODO if slower_target pick target at distance away from loc we're tracking
       if !facing_target?(loc)
         face_target(loc)
         rotate(loc, elapsed_seconds)
         update_acceleration_from(loc)
       end

       orig_speed = @speed
       @speed = tracked_location.ms.speed if reduce_speed

       move_linear(loc, elapsed_seconds)

       @speed = orig_speed if reduce_speed

     else
       nxt = Math::PI  /  6

       self.target = coordinates_from_theta(theta(loc) + nxt)
       face_target(loc, target)
       rotate(loc, elapsed_seconds)
       update_acceleration_from(loc)

       move_linear(loc, elapsed_seconds)
     end
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay,
                         :target     => target    }.merge(trackable_json)
                                                   .merge(rotation_json)
                                                   .merge(linear_json)
                                                   .merge(path_json)
                                                   .merge(axis_json)
     }.to_json(*a)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     "follow-(#{tracked_location_id} at #{distance})"
   end
end
end # module MovementStrategies
end # module Motel
