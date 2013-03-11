# Missions Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Missions

# Permits Mission subsystem to be notified of other subsystem events
# and to notify other subsystems of mission events. Events may specify
# their own callbacks and/or callbacks can be added to the mission
# registry to be run upon an event occurring.
class Event

  class << self
    # @!group Config options

    # Shared RJR::Node used to communicate w/ other subsystems
    attr_accessor :node

    # @!endgroup
  end

  # Unique string id of the event
  attr_accessor :id

  # Timestamp which event is set to occur or did occur
  attr_accessor :timestamp

  # Return boolean if timestamp has since elapsed
  def time_elapsed?
    @timestamp <= Time.now
  end

  # Callbacks to be invoked to run event
  attr_accessor :callbacks

  # Event initializer
  # @param [Hash] args hash of options to initialize event with
  # @option args [String] :id, 'id' id to assign to event
  # @option args [Time] :timestamp, 'timestamp' timestamp to assign to event
  # @option args [Array<Callable>] :callbacks, 'callbacks' callbacks to be run when processing this event
  def initialize(args = {})
    @id        = args[:id]        || args['id']        || ""
    @timestamp = args[:timestamp] || args['timestamp'] || Time.now
    @callbacks = args[:callbacks] || args['callbacks'] || []

    if @timestamp.is_a?(String)
      @timestamp = Time.new(@timestamp)
    end
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :timestamp => timestamp,
                       :callbacks => callbacks}
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

end
end
