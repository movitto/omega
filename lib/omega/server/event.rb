# Omega Server Event definition
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
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
end # module Server
end # module Omega
