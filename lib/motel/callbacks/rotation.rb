# Motel rotation callback definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/callback'

module Motel
module Callbacks

# Defines a {Omega::Server::Callback} to only invoke callback
# if a location rotates a specified minimum axis-angle
class Rotation < Omega::Server::Callback
  # Minimum angle location needs to have rotated
  attr_accessor :rot_theta

  # Axis angle of rotation
  attr_accessor :axis_x, :axis_y, :axis_z

  protected

  # Helper get rotation
  def get_rotation(loc)
    if !(@axis_x.nil? || @axis_y.nil? || @axis_z.nil?)
      Motel.rotated_angle(*loc.orientation, @orig_ox, @orig_oy, @orig_oz,
                          @axis_x, @axis_y, @axis_z)

    # if axis angle is nil/invalid and location movement strategy includes
    # rotate movement strategy mixin, use axis of rotation
    elsif loc.ms.class.ancestors.include?(Motel::MovementStrategies::Rotatable)
      Motel.rotated_angle(*loc.orientation, @orig_ox, @orig_oy, @orig_oz,
                          loc.ms.rot_x, loc.ms.rot_y, loc.ms.rot_z)

    else
      0 # throw err or other?
    end
  end

  # Helper - return bool indicating if min rotation requirement is set
  def check_rotation(loc, old_ox, old_oy, old_oz)
    return if (loc.orientation + [old_ox, old_oy, old_oz]).any? { |o| o.nil? }

    @orig_ox,@orig_oy,@orig_oz = old_ox,old_oy,old_oz if @orig_ox.nil?
    da = get_rotation(loc)

    da.abs >= @rot_theta
  end

  public

  # Motel::Callbacks::Rotation initializer
  #
  # @param [Hash] args hash of options to initialize callback with
  # @option args [Float] :rot_theta,'rot_theta' minium rotation location
  #   needs to undergo before handler in invoked
  def initialize(args = {}, &block)
    attr_from_args args, :rot_theta => 0,
                         :axis_x    => nil,
                         :axis_y    => nil,
                         :axis_z    => nil
    @axis_x = @axis_x.to_f unless @axis_x.nil?
    @axis_y = @axis_y.to_f unless @axis_y.nil?
    @axis_z = @axis_z.to_f unless @axis_z.nil?

    @orig_ox = @orig_oy = @orig_oz = nil

    # only run handler if minimums are met
    @only_if = proc { |*args| self.check_rotation(*args)}

    super(args, &block)
  end

  # Override {Omega::Server::Callback#invoke}, call original then reset
  # local orientation
  #
  # @param [Integer, Float] old_ox old x orientation of location
  # @param [Integer, Float] old_oy old y orientation of location
  # @param [Integer, Float] old_oz old z orientation of location
  def invoke(loc, old_ox, old_oy, old_oz)
    da = get_rotation(loc)
    super(loc, da)
    @orig_ox = @orig_ox = @orig_oz = nil
  end

  # Convert callback to human readable string and return it
  def to_s
    "(#{@rot_theta},#{@axis_x},#{@axis_y},#{@axis_z})"
  end

  # Convert callback to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        { :endpoint_id => @endpoint_id,
          :rot_theta   => @rot_theta,
          :axis_x      => @axis_x,
          :axis_y      => @axis_y,
          :axis_z      => @axis_z }
    }.to_json(*a)
  end

  # Create new callback from json representation
  def self.json_create(o)
    new(o['data'])
  end
end # class Rotation
end # module Callbacks
end # module Motel
