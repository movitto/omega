# Motel rotation callback definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/callback'

module Motel
module Callbacks

# Defines a {Omega::Server::Callback} to only invoke callback
# if a location rotates a specified minimum angle.
#
# The client may specify the minimum overall angle and/or the minimum
# theta or phi angles in the spherical coordinate system
#
# *note* *all* minimum conditions will need to be met to trigger handler!
class Rotation < Omega::Server::Callback
  # Minimum total rotation location needs to have performed to trigger the event
  attr_accessor :min_rotation

  # Minimum rotation of theta the location needs to have performated to trigger the event
  attr_accessor :min_theta

  # Minimum rotation of phi the location needs to have performated to trigger the event
  attr_accessor :min_phi

  protected

  # Helper get rotation
  def get_rotation(loc)
    new_theta,new_phi = loc.spherical_orientation
    old_theta,old_phi,dist = Motel.to_spherical(@orig_ox, @orig_oy, @orig_oz)
    dt = new_theta - old_theta
    dp = new_phi   - old_phi
    da = dt + dp
    [dt,dp,da]
  end

  # Helper - return bool indicating if all min rotation requirements are set
  def check_rotation(loc, old_ox, old_oy, old_oz)
    return if (loc.orientation + [old_ox, old_oy, old_oz]).any? { |o| o.nil? }

    @orig_ox,@orig_oy,@orig_oz = old_ox,old_oy,old_oz if @orig_ox.nil?
    dt,dp,da = get_rotation(loc)

    da.abs >= @min_rotation && dt.abs >= @min_theta && dp.abs >= @min_phi
  end

  public

  # Motel::Callbacks::Rotation initializer
  #
  # @param [Hash] args hash of options to initialize callback with
  # @option args [Float] :min_rotation,'min_rotation' minium rotation location
  #   needs to undergo before handler in invoked
  # @option args [Float] :min_theta,'min_theta' minium theta rotation location
  #   needs to undergo before handler in invoked
  # @option args [Float] :min_phi,'min_phi' minium phi rotation location
  #   needs to undergo before handler in invoked
  def initialize(args = {}, &block)
    attr_from_args args, :min_rotation => 0, :min_theta => 0, :min_phi => 0
    @orig_ox = @orig_oy = @orig_oz = nil

    # only run handler if minimums are met
    @only_if = proc { |*args| self.check_rotation(*args)}

    super(args, &block)
  end

  # Override {Omega::Server::Callback#invoke}, call original then reset local orientation
  #
  # @param [Integer, Float] old_ox old x orientation of location
  # @param [Integer, Float] old_oy old y orientation of location
  # @param [Integer, Float] old_oz old z orientation of location
  def invoke(loc, old_ox, old_oy, old_oz)
    dt,dp,da = get_rotation(loc)
    super(loc, da, dt, dp)
    @orig_ox = @orig_ox = @orig_oz = nil
  end

  # Convert callback to human readable string and return it
  def to_s
    "(#{@min_rotation},#{@min_theta},#{@min_phi})"
  end

  # Convert callback to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        { :endpoint_id => @endpoint_id, :min_rotation => @min_rotation,
          :min_theta => @min_theta, :min_phi => @min_phi}
    }.to_json(*a)
  end

  # Create new callback from json representation
  def self.json_create(o)
    callback = new(o['data'])
    return callback
  end
end # class Rotation
end # module Callbacks
end # module Motel
