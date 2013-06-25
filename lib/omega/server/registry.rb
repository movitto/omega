# Base Registry Class
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'json'

require 'omega/server/event'
require 'omega/server/command'

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

    @validation     ||= proc { |entities, e| true }
    @retrieval      ||= proc { |e| }
  end

  ####################### node / user

  public

  attr_accessor :node

  attr_accessor :user

  attr_accessor :validation

  attr_accessor :retrieval
  
  ####################### entities

  # TODO an 'old_entities' tracker where clients may put items
  # which should be retired from active operation

  def entities(&select)
    init_registry
    @lock.synchronize {
      # by default return everything
      select = proc { |e| true } if select.nil?

      # we use json serialization to perform a deep clone 
      result = Array.new(JSON.parse(@entities.select(&select).to_json))

      # invoke retrieval on each entity
      result.each { |r| @retrieval.call(r) }

      result
    }
  end

  def entity(&select)
    result = self.entities(&select).first
    @retrieval.call(result)
    result
  end

  def clear!
    init_registry
    @lock.synchronize {
      @entities = []
    }
  end

  def <<(entity)
    init_registry
    add = false
    @lock.synchronize {
      add = @validation.call(@entities, entity)
      @entities << entity if add
    }

    self.raise_event(:added, entity) if add
    return add
  end

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
        old_entity = JSON.parse(rentity.to_json)

        # update it
        rentity.update(entity)
      end

    }

    self.raise_event(:updated, rentity, old_entity) unless rentity.nil?
    return !rentity.nil?
  end

  ####################### execution

  def safe_exec
    init_registry
    @lock.synchronize {
      yield @entities
    }
  end

  ####################### events

  def on(eid, &bl)
    init_registry
    @lock.synchronize {
      eid = [eid] unless eid.is_a?(Array)
      eid.each { |id|
        @event_handlers[id] << bl
      }
    }
  end

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

  def run(&lp)
    init_registry
    @lock.synchronize {
      @event_loops << lp
      start_worker(lp) unless @terminate.nil? || @terminate
    }
  end

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

  def stop
    init_registry
    @lock.synchronize {
      @terminate = true
    }
    self
  end

  def join
    init_registry
    @workers.each { |w| w.join }
    self
  end

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
      select { |e| e.kind_of?(Event) && e.time_elapsed? && !e.invoked }.
      each { |evnt|
        RJR::Logger.info "running event #{evnt}"

        # grab global event handlers, add them to callbacks
        h = self.entities.select { |e|
              e.is_a?(EventHandler) && e.event_id == evnt.id
            }.collect { |h| h.handlers }.flatten
        evnt.handlers += h

        # invoke handlers
        begin
          evnt.invoke evnt
        rescue Exception => err
          RJR::Logger.warn "error in event #{evnt}: #{err}"
        end
      }

    DEFAULT_EVENT_POLL
  end

  # Run commands registered in the local registry
  #
  # Optional internal helper method, utilize like so:
  #   run { run_commands }
  def run_commands
    self.entities.
      select { |e| e.kind_of?(Command) }.
      each   { |cmd|
        begin
          # registry/node isn't serialized w/ other
          # cmd json, set on each cmd run
          cmd.registry = self
          cmd.node = self.node

          cmd.run_hooks :first  unless cmd.ran_first_hooks
          cmd.run_hooks :before unless cmd.terminate

          if cmd.should_run?
            cmd.run!
            cmd.run_hooks :after

            if cmd.remove?
              cmd.run_hooks :last
              cmd.terminate!
            end
          end

        rescue Exception => err
          RJR::Logger.warn "error in command #{cmd}: #{err}"
        end
      }

    DEFAULT_COMMAND_POLL
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
      self << JSON.parse(json)
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
