# Base Registry Class
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'json'

require 'omega/server/event'
require 'omega/server/command'
require 'omega/server/proxy'

module Omega
module Server

# Defines a mechanism which provides protected access to
# entities and runs event loops
module Registry
  # Default time loop threads sleep between event cycles
  DEFAULT_LOOP_POLL = 1

  # Default time event loop thread sleeps between event cycles
  DEFAULT_EVENT_POLL = 0.5 # TODO make configurable?

  # Default time command loop thread sleeps between command cycles
  DEFAULT_COMMAND_POLL = 0.5

  class << self
    # @!group Config options

    # Default loop poll
    attr_accessor :loop_poll

    # @!endgroup
  end

  ####################### init

  private

  def init_registry
    @event_loops ||= []
    @loop_poll   ||= Registry.loop_poll || DEFAULT_LOOP_POLL
    @workers     ||= []

    @entities    ||= []
    @lock        ||= Mutex.new

    @event_handlers ||= Hash.new() { |h,k| h[k] = [] }

    @retrieval      ||= proc { |e| }
    @validation_methods ||= []
  end

  ####################### node / user

  public

  attr_accessor :node

  attr_accessor :user

  attr_accessor :validation_methods

  # Add validation method to registry
  def validation_callback(&bl)
    @validation_methods << bl
  end

  attr_accessor :retrieval
  
  ####################### entities

  # TODO an 'old_entities' tracker where clients may put items
  # which should be retired from active operation

  # Return entities for which selector proc returns true
  #
  # Note only copies of entities will be returned, not the
  # actual entities themselves
  def entities(&select)
    init_registry
    @lock.synchronize {
      # by default return everything
      select = proc { |e| true } if select.nil?

      # registry entities
      rentities = @entities.select(&select)

      # invoke retrieval to update each registry entity
      rentities.each { |r| @retrieval.call(r) }

      # we use json serialization to perform a deep clone 
      result = Array.new(RJR.parse_json(rentities.to_json))

      result
    }
  end

  # Return first entity which selector proc returns true
  def entity(&select)
    self.entities(&select).first
  end

  # Clear all entities tracked by local registry
  def clear!
    init_registry
    @lock.synchronize {
      @entities = []
    }
  end

  # Add entity to local registry.
  #
  # Invokes registered validation callbacks before
  # adding to ensure enitity should be added. If
  # any validation returns false, entity will not be
  # added.
  #
  # Raises :added event on self w/ entity
  def <<(entity)
    init_registry
    add = false
    @lock.synchronize {
      add = @validation_methods.all? { |v| v.call(@entities, entity) }
      @entities << entity if add
    }

    self.raise_event(:added, entity) if add
    return add
  end

  # Remove entity from local registry. Entity removed
  # will be first entity for which selector returns true.
  #
  # Raises :delete event on self w/ deleted entity
  def delete(&selector)
    init_registry
    delete = false
    @lock.synchronize {
      entity = @entities.find(&selector)
      delete = !entity.nil?
      @entities.delete(entity) if delete
    }
    self.raise_event(:deleted, entity) if delete
    return delete
  end

  # Update entity in local registry.
  #
  # Entity updated will be first entity for which the
  # selector proc returns true. The entity being
  # updated must define the 'update' method which
  # takes another entity which to copy attributes from/etc.
  #
  # Raises :updated event on self with updated entity
  def update(entity, &selector)
    # TODO default selector ? (such as with_id)
    init_registry
    rentity = nil
    old_entity = nil
    @lock.synchronize {
      # select entity from registry
      rentity = @entities.find &selector

      unless rentity.nil?
        # copy it
        old_entity = RJR.parse_json(rentity.to_json)

        # update it
        rentity.update(entity)
      end

    }

    # TODO make sure proxy operations are kept in sync w/ update operations
    #   (see proxy_for below and ProxyEntity definition)
    self.raise_event(:updated, rentity, old_entity) unless rentity.nil?
    return !rentity.nil?
  end

  # Return proxy objects for entities specified by selector
  # which may be used to update entities safely w/out going
  # directly through the registry
  #
  # TODO invalidate proxies if corresponding entities are deleted ?
  def proxies_for(&selector)
    init_registry
    @lock.synchronize {
      @entities.select(&selector).
                collect { |e| ProxyEntity.new(e, self) }
    }
  end

  # Return a single proxy object for the first matched entity,
  # nil if not found
  def proxy_for(&selector)
    proxies_for(&selector).first
  end

  ####################### execution

  # Safely execute a block of code in the context of the local registry.
  #
  # Pasess the raw entities array to block for unrestricted querying/manipulation
  # (be careful!)
  def safe_exec
    init_registry
    @lock.synchronize {
      yield @entities
    }
  end

  ####################### events

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

  ####################### event loops

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

  # Run events registered in the local registry
  #
  # Optional internal helper method, utilize like so:
  #   run { run_events }
  def run_events
    self.entities.
      select { |e| e.kind_of?(Event) && e.time_elapsed? }.
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
            e.is_a?(Event) && e.id == event.id
          }
        revent.registry = self

        ghandlers =
          entities.select { |e|
            e.is_a?(EventHandler) && e.event_id == event.id
          }.collect { |e| e.handlers }.flatten

        revent.handlers + ghandlers
      }

    # execute handlers outside mutex
    # can't add protection here as some existing handlers
    # won't work w/ it, thus handlers that require it should
    # implement it on their own
    handlers.each { |h|
      RJR::Logger.info "running event #{event}"
      begin
        h.call event
      rescue Exception => err
        RJR::Logger.warn ["error in event handler for #{event}", err] + err.backtrace
      end
    }

    cleanup_event event.id
  end

  public

  # Cleanup an event and handlers specified by id
  def cleanup_event(event_id)
    self.safe_exec { |entities|
      to_remove =
        entities.select { |e|
          (e.is_a?(Event) && e.id == event_id) ||
          (e.is_a?(EventHandler) && e.event_id == event_id) }

      # TODO optional event 'graveyard'
      @entities -= to_remove
    }
  end

  private

  # Run commands registered in the local registry
  #
  # Optional internal helper method, utilize like so:
  #   run { run_commands }
  def run_commands
    self.entities { |e| e.kind_of?(Command) }.
      each   { |cmd|
        begin
          # registry/node isn't serialized w/ other
          # cmd json, set on each cmd run
          cmd.registry = self
          cmd.node = self.node

          cmd.run_hooks :first  unless cmd.ran_first_hooks
          cmd.run_hooks :before

          if cmd.should_run?
            cmd.run!
            cmd.run_hooks :after
          end

          # subsequent commands w/ the same id will break
          # system if command updated is removed from
          # the registry here, use check_command below 
          # to mitigate this
          if cmd.remove?
            cmd.run_hooks :last

            # TODO introduce optional command 'graveyard' at some point
            # to store history of previously executed commands

            delete { |e| e.id == cmd.id &&   # find registry cmd and
                         e.last_ran_at     } # ensure it hasn't been
                                             # swapped out / already deleted
          else
            self << cmd
          end


        rescue Exception => err
          RJR::Logger.warn "error in command #{cmd}: #{err} : #{err.backtrace.join("\n")}"
        end
      }

    DEFAULT_COMMAND_POLL
  end

  # Check commands/enforce unique id's
  #
  # Optional internal helper method, utilize like so:
  #   on(:added) { |c| check_command(c) if c.kind_of?(Omega::Server::Command) }
  def check_command(command)
    @lock.synchronize {
      rcommands = @entities.select { |e| e.id == command.id }
      if rcommands.size > 1
        # keep last one that was added
        ncommand = rcommands.last

        # unless one has an added_at timestamp at at later date
        rcommands.sort! { |c1,c2| c1.added_at <=> c2.added_at }
        ncommand = rcommands.last if rcommands.last.added_at > ncommand.added_at

        @entities -= rcommands
        @entities << ncommand
      end
    }
  end

  ####################### state

  public

  # Save state
  def save(io)
    init_registry
    @lock.synchronize {
      @entities.each { |entity| io.write entity.to_json + "\n" }
    }
  end

  # Restore state
  def restore(io)
    init_registry
    io.each_line { |json|
      self << RJR.parse_json(json)
    }
  end

  ####################### other

  def to_s
    @lock.synchronize {
      "#{self.class}-#{@entities.size}/#{@event_loops.size}/#{@workers.size}"
    }
  end

end # module Registry

end # module Server
end # module Omega
