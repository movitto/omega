# Omega Server Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
module Server

# Omega Event, tracks time and invokes handlers after time has expired
class Event
  # Id of the event
  attr_accessor :id

  # Timestamp which event is set to occur
  attr_accessor :timestamp

  # Boolean indicating if handler was invoked
  attr_accessor :invoked

  # Boolean indicating if event was invalidated
  attr_accessor :invalid

  # Callable objects to be invoked upon event
  attr_accessor :handlers

  # Return boolean if timestamp has elapsed
  def time_elapsed?
    @timestamp <= Time.now
  end

  # Omega::Server::Event initializer
  #
  # @param [Hash] args hash of options to initialize event with
  # @option args [Time] :timestamp, 'timestamp' timestamp to assign to event
  # @option args [Boolean]  :invoked, 'invoked' boolean indicating if the handler was invoked
  # @option args [Boolean]  :invalid, 'invalid' boolean indicating if the event was invalidated
  # @option args [Array<Callable>] :handlers, 'handlers' callable objects to invoke on event
  def initialize(args = {})
    attr_from_args args, :timestamp => Time.now,
                         :handlers  =>       [],
                         :invoked   =>    false,
                         :invalid   =>    false,
                         :id        =>      nil

    @timestamp = Time.parse(@timestamp) if @timestamp.is_a?(String)
  end

  # Update event attributes
  def update(args = {})
    update_from args, :invalid
  end

  # Invoke the registered handler w/ the specified args
  #
  # @param [Array] args catch-all array of args to invoke handler with
  def invoke(*args)
    handlers.each { |h| h.call *args }
    @invoked = true
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id        => id,
                       :invoked   => invoked,
                       :invalid   => invalid,
                       :timestamp => timestamp,
                       :handlers  => handlers}
    }.to_json(*a)
  end

  # Convert event to human readable string and return it
  def to_s
    "event-#{@id}"
  end

  # Create new event from json representation
  def self.json_create(o)
    event = new(o['data'])
    return event
  end
end # class Event

# Periodic event, which automatically schedules another to be
# run at a specified interval on execution
class PeriodicEvent < Event
  # Default interval which will be set if not specified
  DEFAULT_INTERVAL = 60

  # Interval in seconds between spawing events
  attr_accessor :interval

  # Event which to run at the specified interval
  attr_accessor :template_event

  # Handle to registry to used to schedule events
  attr_accessor :registry

  private

  # Handle event, invoke tempate and schedule another
  def handle_event
    # TODO event ids

    # copy template event
    nevent = JSON.parse @template_event.to_json

    # run event
    nevent.invoke nevent

    # schedule next periodic event
    registry << PeriodicEvent.new(:registry  => registry,
                                  :interval  => @interval,
                                  :template_event => @template_event,
                                  :timestamp => Time.now + @interval)
  end

  public

  # Periodic Event initializer
  def initialize(args = {})
    attr_from_args args, :interval => DEFAULT_INTERVAL,
                         :template_event => nil,
                         :registry => nil
    super(args)

    @handlers.unshift proc { |e| handle_event }
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :timestamp => timestamp,
                       :handlers => handlers[1..-1],
                       :interval => interval, :template_event => template_event}
    }.to_json(*a)
  end

end # class PeriodicEvent

# Encapsulates a handler which to be invoked on a future event,
# or one not already created
class EventHandler
  # Event ID which to look for
  attr_accessor :event_id

  # Handlers to invoke when event occurs
  attr_accessor :handlers

  # Boolean indicating if this handler was invalidated
  attr_accessor :invalid

  def initialize(args = {}, &block)
    attr_from_args args, :event_id => nil,
                         :handlers => [block].compact,
                         :invalid  => false
  end

  # Update handler attributes
  def update(args = {})
    update_from args, :invalid
  end

  # Convert handler to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:event_id => event_id,
                       :invalid  => invalid,
                       :handlers => handlers}
    }.to_json(*a)
  end

  # Create new handler from json representation
  def self.json_create(o)
    handler = new(o['data'])
    return handler
  end

end

end # module Server
end # module Omega
