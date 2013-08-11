# The Rotation MovementStrategy model definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'motel/movement_strategy'

module Motel
module MovementStrategies

  # Mixin to include in other modules to provide rotation
  # capabilities while undergoing other movement
  module Rotatable
    # Axis angle describing rotation
    attr_accessor :rot_x, :rot_y, :rot_z, :rot_theta

    # Initialize rotation params from args hash
    def init_rotation(args = {})
      attr_from_args args, :rot_theta => 0,
                           :rot_x     => 0,
                           :rot_y     => 0,
                           :rot_z     => 1
    end

    # Return boolean indicating if rotation parameters are valid
    def valid_rotation?
     @rot_theta.numeric? && @rot_theta > -6.28 && @rot_theta < 6.28 &&
     Motel.normalized?(@rot_x, @rot_y, @rot_z)
    end

    # Rotate the specified location. Takes same parameters
    # as Motel::MovementStrategy#move to update location's
    # orientation after the specified elapsed interval.
    def rotate(loc, elapsed_seconds)
      # update location's orientation
      nor =
        Motel.rotate(loc.orx, loc.ory, loc.orz,
                     @rot_theta * elapsed_seconds,
                     @rot_x, @rot_y, @rot_z)
      loc.orx = nor[0]
      loc.ory = nor[1]
      loc.orz = nor[2]
      loc.orientation
    end

    # Return string representation of rotation
    def rot_to_s
      "#{rot_theta.round_to(2)}/#{rot_x.round_to(2)}/#{rot_y.round_to(2)}/#{rot_z.round_to(2)}"
    end

    # Return rotation params to incorporate in json value
    def rotation_json
      {:rot_theta => rot_theta,
       :rot_x     => rot_x,
       :rot_y     => rot_y,
       :rot_z     => rot_z}
    end
  end

# Rotates a location around its own access at a specified speed.
class Rotate < MovementStrategy
  include Rotatable

  def initialize(args = {})
    init_rotation(args)
    super(args)
  end

  # Return boolean indicating if this movement strategy is valid
  def valid?
    valid_rotation?
  end

  # Implementation of {Motel::MovementStrategy#move}
  def move(loc, elapsed_seconds)
    unless valid?
      ::RJR::Logger.warn \
        "rotate movement strategy (#{rot_to_s}) not valid, not proceeding with move"
      return
    end

    ::RJR::Logger.debug \
      "moving location #{loc.id} via rotate movement strategy #{rot_to_s}"

    rotate(loc, elapsed_seconds)
  end

  # Convert movement strategy to json representation and return it
  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       => { :step_delay => step_delay}.merge(rotation_json)
    }.to_json(*a)
  end

  # Convert movement strategy to human readable string and return it
  def to_s
    "rotate-(#{rot_to_s})"
  end

end

end
end
