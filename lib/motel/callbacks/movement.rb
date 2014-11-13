# Motel movement callback definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/callback'

module Motel
module Callbacks

# Defines a {Omega::Server::Callback} to only invoke callback if a location
# moves a specified minimum distance.
#
# The client may specify the minimum overall distance and/or the minimum
# distance along any axis (x,y,z).
#
# This callback will be invoked with the current location and the
# old x,y,z coordinates individually
#
# *note* *all* minimum conditions will need to be met to trigger handler!
# so if minimum_distance and min_x are specified, the location will have
# need to have moved both the minimum overall distance *and* the minimum
# distance along the x axis.
class Movement < Omega::Server::Callback
  # minimum distance the location needs to move to trigger event.
  attr_accessor :min_distance

  # minimum x,y,z distance the location needs to move to trigger the event
  attr_accessor :min_x, :min_y, :min_z

  protected

  # Helper to get distance moved
  def get_distance(loc)
    dx = loc.x - @orig_x
    dy = loc.y - @orig_y
    dz = loc.z - @orig_z
    d  = Math.sqrt(dx ** 2 + dy ** 2 + dz ** 2)

    [dx,dy,dz,d]
  end

  # Helper, return bool indicating if all min distance requirements are met
  def check_distance(loc, old_x, old_y, old_z)
    # unless original coordinates is nil,
    # ignore old coordinates passed in
    @orig_x,@orig_y,@orig_z = old_x,old_y,old_z if @orig_x.nil?

    dx,dy,dz,d = get_distance(loc)

    d >= @min_distance && dx.abs >= @min_x && dy.abs >= @min_y && dz.abs >= @min_z
  end

  public

  # Motel::Callbacks::Movement initializer
  #
  # @param [Hash] args hash of options to initialize callback with
  # @option args [Integer] :min_distance,'min_distance' minium distance location
  #   needs to move before handler in invoked
  # @option args [Integer] :min_x,'min_x' minium distance location
  #   needs to move along x axis before handler in invoked
  # @option args [Integer] :min_y,'min_y' minium distance location
  #   needs to move along y axis before handler in invoked
  # @option args [Integer] :min_z,'min_z' minium distance location
  #   needs to move along z axis before handler in invoked
  def initialize(args = {}, &block)
    attr_from_args args, :min_distance => 0,
                         :min_x => 0, :min_y => 0, :min_z => 0

    # store original coordinates internally,
    # until minimum distances are satified
    # and callback is invoked, then clear
    @orig_x = @orig_y = @orig_z = nil

    # only run this handler if minimums are specified
    @only_if = proc { |*args| self.check_distance(*args) }

    super(args)
  end

  # Override {Omega::Server::Callback#invoke}, call original then reset local coordinates
  #
  # @param [Motel::Location] loc current location
  # @param [Integer, Float] old_x old x position of location
  # @param [Integer, Float] old_y old y position of location
  # @param [Integer, Float] old_z old z position of location
  def invoke(loc, old_x, old_y, old_z)
    d, dx, dy, dz = get_distance(loc)
    super(loc, d, dx, dy, dz)
    @orig_x = @orig_y = @orig_z = nil
  end

  # Convert callback to human readable string and return it
  def to_s
    "(#{@min_distance},#{@min_x},#{@min_y},#{@min_z})"
  end

  # Convert callback to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        { :endpoint_id => @endpoint_id, :min_distance => @min_distance,
          :min_x => @min_x, :min_y => @min_y, :min_z => @min_z }
    }.to_json(*a)
  end

  # Create new callback from json representation
  def self.json_create(o)
    new(o['data'])
  end
end # class Movement

end # module Callbacks
end # module Motel
