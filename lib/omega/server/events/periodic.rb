# Omega Server Periodic Event definition
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'

module Omega
module Server
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
end # module Server
end # module Omega
