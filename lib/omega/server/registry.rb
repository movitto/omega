# Base Registry Class
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'json'

module Omega
module Server

# Defines a mechanism which provides protected access to
# entities and runs event loops
module Registry
  DEFAULT_LOOP_POLL = 1

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
  end

  ####################### node / user

  public

  attr_accessor :node

  attr_accessor :user

  attr_accessor :validation
  
  ####################### entities

  def entities(&select)
    init_registry
    @lock.synchronize {
      # by default return everything
      select = proc { |e| true } if select.nil?

      # we use json serialization to perform a deep clone 
      Array.new(JSON.parse(@entities.select(&select).to_json))
    }
  end

  def entity(&select)
    self.entities(&select).first
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

  def delete(entity)
    init_registry
    delete = false
    @lock.synchronize {
      delete = @entities.include?(delete)
      @entities.delete(entity)
    }
    self.raise_event(:deleted, entity) if delete
    return delete
  end

  def update(entity, &selector)
    init_registry
    updated = false
    old_entity = nil
    @lock.synchronize {
      # select entity from registry
      rentity = @entities.find &selector
      updated = !rentity.nil?

      if updated
        # copy it
        old_entity = JSON.parse(rentity.to_json)

        # update it
        rentity.update(entity)
      end

    }

    self.raise_event(:updated, entity, old_entity) if updated
    return updated
  end

  ####################### execution

  def safe_exec
    init_registry
    @lock.synchronize {
      yield
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

end # module Registry

end # module Server
end # module Omega