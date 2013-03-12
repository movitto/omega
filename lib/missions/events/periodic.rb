# Missions Periodic Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Missions
module Events

# An event that runs another then schedules another periodic event
# to be executed at the specified interval
class Periodic < Missions::Event
  # Default interval which will be set if not specified
  DEFAULT_INTERVAL = 60

  # Interval in seconds between spawing events
  attr_accessor :interval

  # Event which to run at the specified interval
  attr_accessor :template_event

  # Periodic Event initializer
  def initialize(args = {})
    @interval       = args[:interval] || args['interval'] || DEFAULT_INTERVAL
    @template_event = args[:event]    || args['event']    || nil

    super(args)
    @callbacks << proc { |e|
      # TODO event ids

      # XXX bit of a hacky way to copy template event but works
      nevent = JSON.parse @template_event.to_json

      # run event
      Missions::Registry.instance.create nevent

      # schedule next periodic event
      Missions::Registry.instance.create Periodic.new(:interval  => @interval,
                                                      :event     => @template_event,
                                                      :timestamp => Time.now + @interval)
    }
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :timestamp => timestamp,:callbacks => callbacks[1..-1],
                       :interval => interval, :event => template_event}
    }.to_json(*a)
  end
end

end
end
