# Missions registry
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'singleton'

module Missions

# Primary server side missions tracker
#
# Singleton class, access via Missions::Registry.instance.
class Registry
  include Singleton

  # Time event thread sleeps between event cycles
  EVENT_POLL_DELAY = 0.5 # TODO make configurable?

  # Return array of missions being managed
  #
  # @return [Array<Missions::Mission>]
  def missions
    @registry_lock.synchronize{
      @missions
    }
  end

  # Return events being managed
  #
  # @return [Array<Missions::Event>]
  def events
    @registry_lock.synchronize{
      @events
    }
  end

  # Register global missions event handler/callback
  #
  # @param [String] event_id id of the event which to register handler for
  # @param [Callable] handler callable block to invoke upon executing event
  # @return [String] generated unique identifier of event handle
  def handle_event(event_id, &handler)
    @registry_lock.synchronize{
      handler_id = Motel.gen_uuid
      @event_handlers[event_id] ||= {}
      @event_handlers[event_id][handler_id] = handler
      handler_id
    }
  end

  # Return registered handlers for specified event
  #
  # @param [String] event_id id of the event which to return handlers for
  # @return [Hash{String,Callable}] mapping of handler ids to callable handlers
  def handlers_for(event_id)
    @registry_lock.synchronize{
      @event_handlers.has_key?(event_id) ?
               @event_handlers[event_id] : {}
    }
  end

  # Remove all global event handlers registered for the specified event
  def remove_event_handlers(event_id)
    @registry_lock.synchronize{
      @event_handlers[event_id] = {}
    }
  end

  # Remove global event handler with the specified id
  def remove_event_handler(handler_id)
    @registry_lock.synchronize{
      @event_handlers.keys.each { |event_id|
        @event_handlers[event_id].delete(handler_id)
      }
    }
  end

  # Create new mission or event
  #
  # @param [Missions::Mission,Missions::Event] entity mission or event to add to local registry
  def create(entity)
    @registry_lock.synchronize{
      if(entity.is_a?(Missions::Mission))
        @missions << entity
        entity
      elsif(entity.is_a?(Missions::Event))
        @events << entity
        entity
      else
        nil
      end
    }
  end

  # Remove entity w/ the specified id from the registry
  #
  # For events, will still remove if timeout expired but event
  # hadn't been processed by loop yet, and will ignore
  # if event is no longer on loop (eg already processed
  # and moved to history)
  #
  # @param [String] entity id of the entity to remove
  def remove(entity_id)
    @registry_lock.synchronize{
      # XXX implies global missions & event id namespace
      @missions.reject! { |m| m.id == entity_id }
      @events.reject!   { |e| e.id == entity_id }
    }
  end

  # Run event cycle to process events
  def event_cycle
    until @terminate_cycles
      @registry_lock.synchronize{
        # process events which have elapsed timestamps
        run_events = []
        @events.delete_if { |e| run_events << e if e.time_elapsed? }

        run_events.each   { |e|
          # grab global event handlers, add them to callbacks
          e.callbacks += @event_handlers[e.id].values if @event_handlers.has_key?(e.id)

          # invoke callbacks
          e.callbacks.each { |ecb| ecb.call(e) }

          # add to event history
          @event_history << e
        }
      }
      sleep EVENT_POLL_DELAY
    end
  end

  # Reinitialize the Missions::Registry
  #
  # Clears all local trackers and starts threads to
  # run various cycles
  def init
    @missions       = []
    @events         = []
    @event_history  = []
    @event_handlers = {}

    @registry_lock    = Mutex.new
    @terminate_cycles = false
    @event_thread     = Thread.new { event_cycle }
  end

  # Run the specified block of code as a protected operation.
  #
  # This should be used when updating any missions entities outside
  # the scope of registry operations to protect them from concurrent access.
  #
  # @param [Array<Object>] args catch-all array of arguments to pass to block on invocation
  # @param [Callable] bl block to invoke
  def safely_run(*args, &bl)
    @registry_lock.synchronize {
      bl.call *args
    }
  end

  # Return boolean indicating if registry is running its various worker threads
  def running?
    !@terminate_cycles && !@event_thread.nil? &&
    (@event_thread.status == 'run' || @event_thread.status == 'sleep')
  end

  # Terminate registry worker threads
  def terminate
    @terminate_cycles = true
    @event_thread.join unless @event_thread.nil?
  end

  # Save state of the registry to specified io stream
  def save_state(io)
    missions.each { |m|
      io.write m.to_json + "\n"
    }
    events.each { |e|
      io.write e.to_json + "\n"
    }
    # TODO store event history
  end

  # Restore state of the registry from the specified io stream
  def restore_state(io)
    io.each { |json|
      entity = JSON.parse(json)
      if entity.is_a?(Missions::Mission) || entity.is_a?(Missions::Event)
        create(entity)
      end
    }
  end

end
end
