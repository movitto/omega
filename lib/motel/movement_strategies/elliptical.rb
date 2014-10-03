# The Elliptcial MovementStrategy model definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/common'
require 'motel/movement_strategy'

require 'motel/mixins/elliptical'
require 'motel/mixins/elliptical/generators'

module Motel
module MovementStrategies

# The Elliptical MovementStrategy moves a location
# on an elliptical path described by major/minor
# axis direction vectors, and an eccentricity /
# semi_latus_rectum.
#
# The path equation also depends on the value of the relative_to
# field indicating if the parent location
# is the center or a foci of the ellipse.
# Lastly a speed value is required indicating the
# angular velocity of the location.
#
# To be valid you must specify eccentricity, semi_latus_rectum, and speed
# at a minimum
class Elliptical < MovementStrategy
  include EllipticalAxis
  include EllipticalPath
  include EllipticalMovement
  include EllipticalGenerators

  # Default axis of rotation
  DEFAULT_AXIS = [1,0,0, 0,1,0]

  # Indicates that parent location is at center of elliptical path
  CENTER = "center"

  # Indicates that parent location is at one of the focis of the elliptical path
  FOCI   = "foci"

  # Motel::MovementStrategies::Elliptical initializer
  #
  # @param [Hash] args hash of options to initialize the elliptical
  #   movement strategy with, accepts key/value pairs corresponding
  #   to all movement strategy mutable attributes
  def initialize(args = {})
    axis_from_args     args
    path_from_args     args
    movement_from_args args

    super(args)
  end

  # Return boolean indicating if this movement strategy is valid
  def valid?
    axis_valid? && path_valid? && elliptical_speed_valid?
  end

  # Return attributes by scope
  def scoped_attrs(scope)
    case(scope)
    when :create, :get
      base_attrs + movement_attrs + axis_attrs +
      scoped_path_attrs(scope)
    end
  end

  # Implementation of {Motel::MovementStrategy#move}
  def move(loc, elapsed_seconds)
    # make sure this movement strategy is valid
    unless valid?
       ::RJR::Logger.warn "elliptical movement strategy not valid, not proceeding with move"
       return
    end

    move_elliptical(loc, elapsed_seconds)
  end

  # Convert movement strategy to json representation and return it
  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       => base_json.merge(movement_json).
                                merge(path_json).
                                merge(axis_json)
    }.to_json(*a)
  end

  # Convert movement strategy to human readable string and return it
  def to_s
    "elliptical-(rt_#{relative_to}/s#{speed}/e#{e}/p#{p}/d#{direction})"
  end
end # class Elliptical
end # module MovementStrategies
end # module Motel
