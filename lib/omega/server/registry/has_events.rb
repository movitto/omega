# Base Registry HasEntities Mixin
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
module Server
module Registry
  module HasEvents
    def init_event_handlers
      @event_handlers ||= Hash.new() { |h,k| h[k] = [] }
    end

    # Register block to be invoked on specified event(s)
    def on(eid, &bl)
      init_registry
      @lock.synchronize {
        eid = [eid] unless eid.is_a?(Array)
        eid.each { |id|
          @event_handlers[id] << bl
        }
      }
    end

    # Raises specified event, invoking registered handlers
    def raise_event(event, *params)
      init_registry
      handlers = []
      @lock.synchronize{
        handlers =
          @event_handlers[event] if @event_handlers.has_key?(event)
      }
      handlers.each { |h| h.call *params }
      nil
    end
  end # module HasEvents
end # module Registry
end # module Server
end # module Omega
