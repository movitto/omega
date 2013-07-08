# Motel proximity callback definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/callback'

module Motel
module Callbacks

# Defines a {Omega::Server::Callback} to only invoke callback
# if two locations are within the specified maximum distance of each other.
#
# The client may specify the maximum overall distance and/or the maximum
# distance along any axis (x,y,z).
#
# *note* *all* maximum conditions will need to be met to trigger handler!
# So if maximum_distance and max_x are specified, the location will have
# need to have moved both the minimum overall distance *and* the minimum
# distance along the x axis.
class Proximity < Omega::Server::Callback
  # [Motel::Location] which to compare proximity of other location to
  attr_accessor :to_location

  # [:proximity,:entered_proximity,:left_proximity] Proximity event which to trigger on.
  #
  # May correspond to:
  # * :proximity - trigger callback handler every time when locations are in proximity
  # * :entered_proximity - trigger callback handler only once after every time locations enter proximity of each other
  # * :left_proximityy - trigger callback handler only once after every time locations leave proximity of each other
  attr_accessor :event

  # Max distance the locations needs to be apart to trigger event
  attr_accessor :max_distance

  # Max x,y,z distance the locations need to be to trigger the event
  attr_accessor :max_x, :max_y, :max_z

  protected

  def currently_in_proximity(loc)
    dx = (loc.x - to_location.x).abs
    dy = (loc.y - to_location.y).abs
    dz = (loc.z - to_location.z).abs
    d  = Math.sqrt(dx ** 2 + dy ** 2 + dz ** 2)

    (d <= @max_distance) || (dx <= @max_x && dy <= @max_y && dz <= @max_z)
  end

  def check_proximity(loc)
    cip = currently_in_proximity(loc)
    (cip &&  (@event == :proximity ||
             (@event == :entered_proximity &&
              !@locations_in_proximity))) ||
    (!cip && (@event == :left_proximity &&
              @locations_in_proximity))
  end

  public

  # Motel::Callbacks::Movement initializer
  #
  # @param [Hash] args hash of options to initialize callback with
  # @option args [String] :event,'event' proximity event on which to trigger hander see {#event}
  # @option args [Integer] :max_distance,'max_distance' maximum distance locations
  #   can be apart to trigger handler
  # @option args [Integer] :max_x,'max_x' maximum distance locations
  #   can be apart to trigger handler
  # @option args [Integer] :max_y,'max_y' maximum distance locations
  #   can be apart to trigger handler
  # @option args [Integer] :max_z,'max_z' maximum distance locations
  #   can be apart to trigger handler
  # @option args [Motel::Location] :to_location,'to_location' location which
  #   to compare that specified to {Omega::Server::Callback#invoke} to to determine proximity
  def initialize(args = {}, &block)
    attr_from_args args,
                   :max_distance => 0,
                   :max_x => 0, :max_y => 0, :max_z => 0,
                   :to_location => nil, :event => :proximity

    self.event = event.intern if event.is_a?(String)

    # keep track of proximity state internally for different event types
    @locations_in_proximity = false

    # only run handler if conditions are met
    @only_if = proc { |*args| self.check_proximity(*args) }

    super(args, &block)
  end

  # Override {Omega::Server::Callback#invoke}, set locations_in_proximity
  # @param [Motel::Location] loc location which to compare against @to_location
  def invoke(loc)
    super(loc, to_location)
    @locations_in_proximity = currently_in_proximity(loc)
  end

  # Convert callback to human readable string and return it
  def to_s
    "(#{@max_distance},#{@max_x},#{@max_y},#{@max_z})"
  end

  # Convert callback to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        { :endpoint_id => @endpoint_id, :max_distance => @max_distance,
          :max_x => @max_x, :max_y => @max_y, :max_z => @max_z,
          :to_location => @to_location, :event => @event}
    }.to_json(*a)
  end

  # Create new callback from json representation
  def self.json_create(o)
    callback = new(o['data'])
    return callback
  end
end # class Proximity
end # module Callbacks
end # module motel
