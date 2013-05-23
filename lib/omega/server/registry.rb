# Base Registry Class
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'singleton'

module RJR

# Defines a mechanism which provides protected access to
# entities and runs event loops
module Registry
  ####################### init

  private

  def init_registry
    @terminate   ||= false
    @event_loops ||= []
    @workers     ||= []

    @entities    ||= []
    @lock        ||= Mutex.new

    @event_handlers ||= Hash.new([])
  end

  ####################### node / user

  public

  attr_accessor :node

  attr_accessor :user
  
  ####################### entities

  def entities
    @lock.synchronize {
      # TODO deep clone all entities
      Array.new(@entities)
    }
  end

  def clear(entity)
    @lock.synchronize {
      @entities = []
    }
  end

  def <<(entity)
    @lock.synchronize {
      @entities << entity
    }

    raise_event(:added, entity)
  end

  # Take a block to check and evaluate return value if entity is registered
  def add_if(entity, &bl)
    v = false
    @lock.synchronize {
      v = bl.call self
      self << entity if v
    }
    v
  end

  def update(entity, new_entity)
    @lock.synchronize {
      entity.update(new_entity)
    }

    self.raise_event(:updated) # TODO pass in new/old entities
  end

  ####################### execution

  def safe_exec
    @lock.synchronize {
      yield
    }
  end

  ####################### events

  def on(eid, &bl)
    @lock.synchronize {
      eid = [eid] unless eid.is_a?(Array)
      eid.each { |id|
        @event_handlers[id] << bl
      }
    }
  end

  def raise_event(event, *params)
    handlers = []
    @lock.synchrnozie{
      handlers =
        @event_handlers[eid] if @event_handlers.has_key?(eid)
    }
    handlers.each { |h| h.call *params }
    nil
  end

  ####################### event loops

  def run(&lp)
    @lock.synchronze {
      @event_loops << lp
      start_worker(lp) unless @terminate
    }
  end

  def start
    @lock.synchronize {
      @terminate = false
      @event_loops.each { |lp|
        start_worker(lp)
      }
    }
  end

  def stop
    @lock.synchronize {
      @terminate = true
    }
  end

  def join
    @workers.each { |w| w.join }
  end

  def running?
  end

  def start_worker(lp)
    @workers <<
      Thread.new(lp){ |lp|
        until @terminate
          sl = lp.call
          sl ||= @loop_poll
          sleep sl
        end
      }
  end

  ####################### state

  private

  # Save state
  def save(io)
    @lock.synchronize {
      @entities.each { |entity| io.write loc.to_json + "\n" }
    }
  end

  # Restore state
  def restore(io)
    io.each { |json|
      self << JSON.parse(json)
    }
  end

  private

end # module Registry

end # module Omega
