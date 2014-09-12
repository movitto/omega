# Motel Runs Locations Events Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'

module Motel
module RunsLocationEvents
  protected

  # Register new location event.
  # Assumes we're calling from within the lock
  def register_location_event(loc, *args)
    @location_events ||= []
    @location_events << [loc, args]
  end

  public

  def run_location_events
    events = []

    @lock.synchronize {
      events = @location_events if @location_events
      @location_events = []
    }

    events.each { |loc_event|
      loc   = loc_event[0]
      event = loc_event[1]

      @lock.synchronize {
        begin
          loc.raise_event(*event)
        rescue => e
          msg = "error running location callbacks for #{loc.id}: #{e.to_s}"
          ::RJR::Logger.warn msg
          ::RJR::Logger.warn e.backtrace
        end
      }
    }

  end
end # module RunsLocationEvents
end # module Motel
