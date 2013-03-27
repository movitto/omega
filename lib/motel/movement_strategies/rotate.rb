# The Rotation MovementStrategy model definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Motel
module MovementStrategies

  # Mixin to include in other modules to provide rotation
  # capabilities while undergoing other movement
  module Rotatable
    # Angular speed which location is rotating
    attr_accessor :dtheta, :dphi

    # Initialize rotation params from args hash
    def init_rotation(args = {})
     @dtheta               = args[:dtheta]|| args['dtheta'] || 0
     @dphi                 = args[:dphi]  || args['dphi']   || 0
    end

    # Return boolean indicating if rotation parameters are valid
    def valid_rotation?
     (@dtheta.nil? || ([Float, Fixnum].include?(@dtheta.class) && @dtheta > -6.28 && @dtheta < 6.28)) &&
     (@dphi.nil?   || ([Float, Fixnum].include?(@dphi.class)   && @dphi   > -6.28 && @dphi   < 6.28))
    end

    # Rotate the specified location. Takes same parameters
    # as Motel::MovementStrategy#move to update location's
    # orientation after the specified elapsed interval.
    def rotate(location, elapsed_seconds)
      # update location's orientation
      loct, locp = location.spherical_orientation
      unless loct.nil? || locp.nil?
        loct += dtheta * elapsed_seconds
        locp += dphi   * elapsed_seconds
        location.orientation_x,location.orientation_y,location.orientation_z =
          Motel.from_spherical(loct, locp, 1)
      end
    end

    # Return rotation params to incorporate in json value
    def rotation_json
      {:dtheta => dtheta, :dphi => dphi}
    end
  end

# Rotates a location around its own access at a specified speed.
#
# Speed is specified here as units in a spherical coordinate system
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
  def move(location, elapsed_seconds)
    unless valid?
      RJR::Logger.warn "rotate movement strategy (#{self.to_s}) not valid, not proceeding with move"
      return
    end

    RJR::Logger.debug "moving location #{location.id} via rotate movement strategy #{dtheta}/#{dphi}"
    rotate(location, elapsed_seconds)
  end

  # Convert movement strategy to json representation and return it
  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       => { :step_delay => step_delay}.merge(rotation_json)
    }.to_json(*a)
  end

  # Convert movement strategy to human readable string and return it
  def to_s
    "rotate-(#{@dtheta}/#{@dphi})"
  end
end

end
end
