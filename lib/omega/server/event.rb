# Omega Server Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/util/json_parser'

module Omega
module Server

# Omega Event, tracks time and invokes handlers after time has expired
class Event
  # Id of the event
  attr_accessor :id

  # Optional type of event
  attr_accessor :type

  # TODO also add a 'tags' field
  # (clients should be able to subscribe to events w/ any tag)

  # Timestamp which event is set to occur
  attr_accessor :timestamp

  # Callable objects to be invoked upon event
  attr_accessor :handlers

  # Handle to registry event is running in
  attr_accessor :registry

  # Return boolean if timestamp has elapsed
  def time_elapsed?
    @timestamp <= Time.now
  end

  # Return boolean indicating if all checks pass for event execution
  def should_exec?
    time_elapsed?
  end

  # Omega::Server::Event initializer
  #
  # @param [Hash] args hash of options to initialize event with
  # @option args [Time] :timestamp, 'timestamp' timestamp to assign to event
  # @option args [Array<Callable>] :handlers, 'handlers' callable objects to invoke on event
  def initialize(args = {})
    attr_from_args args, :timestamp => Time.now,
                         :handlers  =>       [],
                         :id        =>      nil,
                         :registry  =>      nil,
                         :type      =>      nil

    @timestamp = Time.parse(@timestamp) if @timestamp.is_a?(String)
  end

  # Optional args which may be attached to class.
  # Meant for subclasses, not used in central omega subsystem
  def event_args
  end

  # Invoke the registered handler w/ the specified args
  #
  # @param [Array] args catch-all array of args to invoke handler with
  def invoke(*args)
    handlers.each { |h| h.call *args }
    @invoked = true
  end

  # Include handlers in json data
  def handlers_json
    {:handlers => handlers}
  end

  # Return event json data
  def json_data
    {:id        => id,
     :type      => type,
     :timestamp => timestamp}.merge(handlers_json)
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => json_data
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

# Event with built in handler
class HandledEvent < Event
  def initialize(args = {})
    super(args)

    @handlers.unshift proc { |e| handle_event }
  end

  private

  # Handle event, override to define custom event handler
  def handle_event
  end

  public

  # Omit locally managed handler from handlers
  def handlers_json
    {:handlers => handlers[1..-1]}
  end
end

# Periodic event, which automatically schedules another to be
# run at a specified interval on execution
class PeriodicEvent < HandledEvent
  # Default interval which will be set if not specified
  DEFAULT_INTERVAL = 60

  # Interval in seconds between spawing events
  attr_accessor :interval

  # Event which to run at the specified interval
  attr_accessor :template_event

  private

  # Handle event, invoke template and schedule another
  def handle_event
    # copy template event
    nevent = RJR::JSONParser.parse @template_event.to_json

    # add event to registry to be run
    registry << nevent

    # generate an id
    nid = nil
    unless id.nil?
      nid = id.split('-')
      if nid[-1].numeric_string?
        nid[-1] = nid[-1].to_i + 1
      else
        nid << "1"
      end
      nid = nid.join('-')
    end

    # schedule next periodic event
    registry << PeriodicEvent.new(:id => nid,
                                  :interval  => @interval,
                                  :template_event => @template_event,
                                  :timestamp => Time.now + @interval)
  end

  public

  # Periodic Event initializer
  def initialize(args = {})
    attr_from_args args, :interval => DEFAULT_INTERVAL,
                         :template_event => nil
    super(args)
  end

  # Return periodic event json data
  def periodic_json_data
    {:interval       => interval,
     :template_event => template_event}
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => json_data.merge(periodic_json_data)
    }.to_json(*a)
  end
end # class PeriodicEvent

# Encapsulates a handler which to be invoked on a future event,
# or one not already created
class EventHandler
  # Event ID which to look for
  attr_accessor :event_id

  # Event Type which to look for
  attr_accessor :event_type

  # Handlers to invoke when event occurs
  attr_accessor :handlers

  # Set true to keep event handler in registry after execution
  attr_accessor :persist

  # RJR Node Endpoint which this handler is registered for
  attr_accessor :endpoint_id

  def initialize(args = {}, &block)
    attr_from_args args, :event_id => nil,
                         :event_type => nil,
                         :handlers => [block].compact,
                         :persist  => false,
                         :endpoint_id => nil
  end

  # Return bool indicating if this handles is meant for the specified event
  def matches?(event)
    (event_id.nil?   || event_id   == event.id) &&
    (event_type.nil? || event_type == event.type)
  end

  def exec(&block)
    @handlers << block
  end

  # Run handlers, note this method *isn't* invoked in registry event cycle
  def invoke(*args)
    @handlers.each { |h|
      h.call *args
    }
  end

  # Include handlers in json data
  def handlers_json
    {:handlers => handlers}
  end

  # Return event handler json data
  def json_data
    {:event_id    => event_id,
     :event_type  => event_type,
     :persist     => persist,
     :endpoint_id => endpoint_id}.merge(handlers_json)
  end


  # Convert handler to json representation and return it
  #
  # XXX handlers allows us to pass procs through registry serialization
  # to where they need to be used which is required but is iffy at best
  # (eg registry serialization shouldn't be bypassed though there is
  #  no security vulnerabilty because of this AFAIK).
  #
  # Look into a more robust solution for this (perhaps static
  # EventHandler specific callbacks or something similar to the missions
  # dsl proxy system)
  #
  # Also applies to to_json methods in EventHandler subclasses
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => json_data
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
