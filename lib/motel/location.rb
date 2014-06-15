# The Location entity
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/util/json_parser'
require 'omega/common'

require 'motel/mixins'

module Motel

# Locations are the entity at the center of the Motel subsystem
# and describe a set of x,y,z coordinates in cartesian space.
#
# The location may be related to a parent through its parent_id
# and parent properties, in which case the x,y,z coordinates reference
# the position in and/or relative to its parent.
#
# If no parent_id / parent is specified, the location is often assumed
# to be the 'root' location of its local system. Ultimately though the
# sematics of the location heirarchy is left up to the client.
#
# A location is associated with a instance of a {Motel::MovementStrategy} subclass,
# by default {Motel::MovementStrategies::Stopped}. The movement_strategy#move
# method is invoked by the {Motel::Runner} with the location instance
# on every run cycle.
class Location
  include BaseAttrs
  include InHeirarchy
  include HasCoordinates
  include HasOrientation
  include HasMovementStrategy
  include EventDispatcher
  include Trackable
  include Generators

  # Location initializer
  # @param [Hash] args hash of options to initialize location with, accepts
  #   key/value pairs corresponding to all mutable location attributes
   def initialize(args = {})
      reset_tracked_attributes

      base_attrs_from_args args
      coordinates_from_args args
      orientation_from_args args
      movement_strategy_from_args args
      callbacks_from_args args
      heirarchy_from_args args
      trackable_state_from_args args
   end

   # Return all updatable attributes
   def updatable_attrs
     updatable_base_attrs      + coordinates_attrs +
     updatable_heirarchy_attrs + orientation_attrs +
     updatable_trackable_attrs + movement_strategy_attrs
   end

   # Update this location's attributes from other location
   #
   # @param [Motel::Location] location location from which to copy values from
   def update(location)
      update_from(location, *updatable_attrs)
   end

   # Validate the location's properties
   #
   # @return bool indicating if the location is valid or not
   #
   # Currently tests
   # * id is set
   # * x, y, z are numeric
   # * orientation is numeric
   # * movement strategy is valid
   def valid?
     id_valid? && coordinates_valid? &&
     orientation_valid? && movement_strategy_valid?
   end

   # Return attributes by scope
   def scoped_attrs(scope)
     case(scope)
     when :create
       base_attrs + coordinates_attrs + orientation_attrs +
                      scoped_heirarchy_attrs(scope) || [] +
              scoped_movement_strategy_attrs(scope) || []
     end
   end

   # Return all json attributes
   def json_attrs
     base_attrs           + coordinates_attrs +
     heirarchy_json_attrs + orientation_attrs +
     trackable_attrs      + movement_strategy_attrs +
     callbacks_attrs
   end

   # Convert location to json representation and return it
   def to_json(*a)
     { 'json_class' => self.class.name,
       'data'       => base_json.merge(coordinates_json).
                                 merge(trackable_json).
                                 merge(orientation_json).
                                 merge(heirarchy_json).
                                 merge(movement_strategy_json).
                                 merge(callbacks_json)
     }.to_json(*a)
   end

   # Convert location to human readable string and return it
   def to_s
     attr_str =       parent_id_str   +
                ':' + coordinates_str +
                '>' + orientation_str +
                " via #{movement_strategy}"

     "loc##{id}(#{attr_str})"
   end

   # Create new location from json representation
   def self.json_create(o)
     loc = new(o['data'])
     return loc
   end

   # Return clone of location
   def clone
     RJR::JSONParser.parse self.to_json
   end
end # class Location
end # module Motel
