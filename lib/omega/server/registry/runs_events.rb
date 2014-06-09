# Base Registry RunsEvents Mixin
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'
require 'omega/server/events'
require 'omega/server/event_handler'

module Omega
module Server
module Registry
  module RunsEvents
    # Default time loop threads sleep between event cycles
    DEFAULT_LOOP_POLL = 1

    # Default time event loop thread sleeps between event cycles
    DEFAULT_EVENT_POLL = 0.5 # TODO make configurable?

    private

    def init_event_loops
      @event_loops ||= []
      @loop_poll   ||= Registry.loop_poll || DEFAULT_LOOP_POLL
      @workers     ||= []
    end

    public

    # Return the specified event loop in a new worker
    #
    # The workers will delay for the amount of type specified
    # by the return value of the event loop before running it again.
    def run(&lp)
      init_registry
      @lock.synchronize {
        @event_loops << lp
        start_worker(lp) unless @terminate.nil? || @terminate
      }
    end

    # Star the event loop workers
    def start
      init_registry
      @lock.synchronize {
        @terminate = false
        @event_loops.each { |lp|
          start_worker(lp)
        }
      }
      self
    end

    # Stop the event loop works and subsequent invocations
    def stop
      init_registry
      @lock.synchronize {
        @terminate = true
      }
      self
    end

    # Join all event loop workers
    def join
      init_registry
      @workers.each { |w| w.join }
      self
    end

    # Return boolean indicating if events loops are running
    def running?
      init_registry
      @lock.synchronize {
        !@terminate &&
        @workers.collect { |w| w.status }.all? { |s| ['sleep', 'run'].include?(s) }
      }
    end

    private

    # remove any duplicate event handlers,
    # keeping the specified one
    def sanitize_event_handlers(event_handler)
      @lock.synchronize {
        handlers = @entities.select { |h|
          h.kind_of?(Omega::Server::EventHandler) &&
          (h.event_id.nil?   || h.event_id   == event_handler.event_id)   &&
          (h.event_type.nil? || h.event_type == event_handler.event_type) &&
          h.endpoint_id == event_handler.endpoint_id
        }

        handlers.delete(event_handler)
        @entities -= handlers
      }
    end

    def start_worker(lp)
      th =
        Thread.new(lp){ |lp|
          until @terminate
            sl = lp.call
            sl ||= @loop_poll
            sleep sl
          end

          @lock.synchronize { @workers.delete(th) }
        }
      @workers << th
    end

    # TODO split out run_events / run_event / cleanup_events into it's own module ?

    # Run events registered in the local registry
    #
    # Optional internal helper method, utilize like so:
    #   run { run_events }
    def run_events
      self.entities { |e| e.kind_of?(Event) && e.time_elapsed? }.
           each { |evnt| run_event(evnt) }

      DEFAULT_EVENT_POLL
    end

    # Run a single registry event
    #
    # XXX Needed as events and eventhandlers have callable methods
    # which aren't serialized so must access registry entries directly
    #
    # Helper used internally, do not use externally
    def run_event(event)
      handlers =
        self.safe_exec { |entities|
          revent =
            entities.find { |e|
              e.kind_of?(Event) && e.id == event.id
            }
          revent.registry = self

          ghandlers =
            entities.select { |e|
              e.kind_of?(EventHandler) && e.matches?(event)
            }.collect { |e| e.handlers }.flatten

          # TODO at some point should change this to dispatch through
          # the events & handlers themselves (eg Event & EventHandler #invoke)
          revent.handlers + ghandlers
        }

      # execute handlers outside mutex
      # can't add protection here as some existing handlers
      # won't work w/ it, thus handlers that require it should
      # implement it on their own
      handlers.each { |h|
        RJR::Logger.info "running event #{event} handler #{h}"
        begin
          h.call event
        rescue Exception => err
          RJR::Logger.warn ["error in event handler for #{event}", err] + err.backtrace
        end
      }

      cleanup_event event
    end

    public

    # Cleanup specified event and handlers
    # Skip event handlers marked as persistant
    def cleanup_event(event)
      self.safe_exec { |entities|
        # Lookup event if user specified event id
        event = entities.find { |e| e.is_a?(Event) &&
                                    e.id == event     } if event.is_a?(String)
        return if event.nil?

        to_remove =
          entities.select { |e|
            (e.is_a?(Event) && e.id == event.id) ||
            (e.is_a?(EventHandler) && e.matches?(event) && !e.persist) }

        # TODO optional event 'graveyard'
        @entities -= to_remove
      }
    end
  end # module RunsEvents
end # module Registry
end # module Server
end # module Omega
