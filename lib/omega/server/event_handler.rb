# Omega Server Event Handler definition
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
module Server
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
  end # class EventHandler
end # module Server
end # module Omega
