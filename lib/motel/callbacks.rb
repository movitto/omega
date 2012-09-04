# Motel callback definitions
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/location'

module Motel

module Callbacks

# Base Motel callback interface, through which a specified handler may
# be invoked on certain conditions.
#
# Instantiate a callback with a handler to invoke and the endpoint (rjr node) which
# the handler is for. When the callback is ready to be used, the {#invoke} method
# will invoke the handler with the specified argument list
#
# Subclasses should override the 'initialize' and 'invoke' methods to store
# conditions to check before invoking 'super' with the desired args to
# invoke the handler
#
# @see Motel::Callbacks::Movement
# @see Motel::Callbacks::Proximity
class Base
  # Callable object to be invoked upon callback event
  attr_accessor :handler

  # Endpoing (rjr node) which this callback is being used for
  attr_accessor :endpoint_id

  # Motel::Callbacks::Base initializer
  #
  # @param [Hash] args hash of options to initialize callback with
  # @option args [Callable] :handler,'handler' handler to invoke on the event
  # @param [Callable] block handler to invoke on the event (will be set to the block parameter passed in if specified)
  # @option args [String] :endpoint,'endpoint' endpoint registering this callback
  def initialize(args = {}, &block)
    @handler = args[:handler] if args.has_key?(:handler)
    @handler = block if block_given?

    @endpoint_id = args[:endpoint] || args['endpoint']
  end

  # Invoke the registered handler w/ the specified args
  #
  # @param [Array] args catch-all array of args to invoke handler with
  def invoke(*args)
    handler.call *args
  end

end

# Extends the {Motel::Callbacks::Base} interface to only invoke callback
# if a location moves a specified minimum distance.
#
# The client may specify the minimum overall distance and/or the minimum
# distance along any axis (x,y,z).
#
# *note* *all* minimum conditions will need to be met to trigger handler!
# So if minimum_distance and min_x are specified, the location will have
# need to have moved both the minimum overall distance *and* the minimum
# distance along the x axis.
class Movement < Base
  # Minimum distance the location needs to move to trigger event.
  attr_accessor :min_distance

  # Minimum x,y,z distance the location needs to move to trigger the event
  attr_accessor :min_x, :min_y, :min_z

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
    @min_distance = args[:min_distance] || args['min_distance'] || 0
    @min_x        = args[:min_x]        || args['min_x']        || 0
    @min_y        = args[:min_y]        || args['min_y']        || 0
    @min_z        = args[:min_z]        || args['min_z']        || 0

    # store original coordinates internally,
    # until minimum distances are satified
    # and callback is invoked, then clear
    @orig_x = @orig_y = @orig_z = nil

    super(args, &block)
  end

  # Calculate distance between location and old coordinates, and
  # invoke handler w/ location if minimums are true
  #
  # @param [Motel::Location] new_location current position of location to check
  # @param [Integer, Float] old_x old x position of location
  # @param [Integer, Float] old_y old y position of location
  # @param [Integer, Float] old_z old z position of location
  def invoke(new_location, old_x, old_y, old_z)
     # unless original coordinates is nil, ignore old coordinates passed in
     if @orig_x.nil?
       @orig_x = old_x
       @orig_y = old_y
       @orig_z = old_z
     end

     dx = new_location.x - @orig_x
     dy = new_location.y - @orig_y
     dz = new_location.z - @orig_z
     d  = Math.sqrt(dx ** 2 + dy ** 2 + dz ** 2)

     if d >= @min_distance && dx.abs >= @min_x && dy.abs >= @min_y && dz.abs >= @min_z
       super(new_location, d, dx, dy, dz)
       @orig_x = @orig_y = @orig_z = nil
     end
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
        { :endpoint => @endpoint_id, :min_distance => @min_distance,
          :min_x => @min_x, :min_y => @min_y, :min_z => @min_z }
    }.to_json(*a)
  end

  # Create new callback from json representation
  def self.json_create(o)
    callback = new(o['data'])
    return callback
  end
end # class Movement

# Extends the {Motel::Callbacks::Base} interface to only invoke callback
# if two locations are within the specified maximum distance of each other.
#
# The client may specify the maximum overall distance and/or the maximum
# distance along any axis (x,y,z).
#
# *note* *all* maximum conditions will need to be met to trigger handler!
# So if maximum_distance and max_x are specified, the location will have
# need to have moved both the minimum overall distance *and* the minimum
# distance along the x axis.
class Proximity < Base
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
  #   to compare that specified to {#invoke} to to determine proximity
  def initialize(args = {}, &block)
    @to_location = nil
    @event = :proximity

    @max_distance = args[:max_distance] || args['max_distance'] || 0
    @max_x = args[:max_x] || args['max_x'] || 0
    @max_y = args[:max_y] || args['max_y'] || 0
    @max_z = args[:max_z] || args['max_z'] || 0
    @to_location = args[:to_location] || args['to_location']
    @event = args[:event].intern  if args.has_key?(:event)  && args[:event].is_a?(String)
    @event = args['event'].intern if args.has_key?('event') && args['event'].is_a?(String)

    # keep track of proximity state internally for different event types
    @locations_in_proximity = false

    super(args, &block)
  end

  # Calculate distance between specified location and stored one,
  # invoke handler w/ specified location if they are within proximity
  #
  # @param [Motel::Location] location location which to compare against @to_location
  def invoke(location)
     dx = (location.x - to_location.x).abs
     dy = (location.y - to_location.y).abs
     dz = (location.z - to_location.z).abs
     d  = Math.sqrt(dx ** 2 + dy ** 2 + dz ** 2)

     currently_in_proximity  = (d <= @max_distance) || (dx <= @max_x && dy <= @max_y && dz <= @max_z)
     trigger_callback = (currently_in_proximity &&  (@event == :proximity ||
                                                    (@event == :entered_proximity &&
                                                     !@locations_in_proximity))) ||
                        (!currently_in_proximity && (@event == :left_proximity &&
                                                     @locations_in_proximity))

     @locations_in_proximity = currently_in_proximity

     super(location, to_location) if trigger_callback
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
        { :endpoint => @endpoint_id, :max_distance => @max_distance,
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
end # module Motel
