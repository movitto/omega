# Motel Registry tracks all locations
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'
require 'rjr/common'
require 'omega/server/registry'

module Motel

# Motel::Registry is a singleton class/object which acts as the primary
# mechanism to run locations in the system.
class Registry
  LOCATION_EVENTS = [:movement, :rotation, :proximity, :stops]

  include Singleton
  include RJR::Registry

  private

  def run_location(loc)
    RJR::Logger.debug "runner moving location #{loc}"

    old_coords,old_orientation = loc.corrdinates,loc.orientation

    begin
      loc.movement_strategy.move loc, elapsed
      loc.last_moved_at = Time.now

      # invoke movement and rotation callbacks
      # TODO invoke these async so as not to hold up the runner
      self.raise_event(:movement, loc, *old_coords)
      self.raise_event(:rotation, loc, *old_orientation)

    rescue Exception => e
      RJR::Logger.warn "error running location/callbacks for #{loc.id}: #{e.to_s}"
    end
  end

  def run_locations
    delay = 0
    self.entities.each { |loc|
      loc.last_moved_at ||= Time.now
      elapsed = Time.now - loc.last_moved_at

      if elapsed > loc.movement_strategy.step_delay
        run_location(loc)

      else
        remaining = loc.movement_strategy.step_delay - elapsed
        delay = remaining if remaining < delay

      end
    }

    # invoke all proximity_callbacks afterwards
    begin
      self.entities.each { |loc| self.raise_event(:proximity, loc) }
    rescue Exception => e
      RJR::Logger.warn "error running proximity callbacks for #{loc.id}: #{e.to_s}"
    end

    delay == 0 ? nil : delay
  end

  def adjust_heirarchry(nloc, oloc=nil)
    @lock.synchronize{
      nparent = @entities.find { |l| l.id == nloc.parent_id }
      oparent = oloc.nil? ? nil : @entities.find { |l| l.id == oloc.parent_id }

      if oparent != nparent 
        oparent.remove_child(nloc) unless oparent.nil?

        # TODO if nparent.nil? throw error?
        nparent.add_child(nloc) unless nparent.nil?
        nloc.parent = nparent
      end

    }
  end

  def check_location(nloc, oloc=nil)
    @lock.synchronize{
      # if follow movement strategy, update location from tracked_location_id
      if nloc.ms.is_a?(Motel::Follow)
        node.ms.track_location =
          @entities.find { |l|
            l.id == node.ms.tracked_location_d
          }
      end

      # if changing movement strategy
      if !oloc.nil? && oloc.ms != nloc.ms
        # if changing to stopped movement strategy
        if nloc.ms.is_a?(Stopped)
          self.raise_event(:stops, nloc)
        end

        # self.raise_event(:strategy) # TODO
      end
    }
  end

  public

  def initialize
    init_registry

    # validate location ids are unique before creating
    self.validation = proc { |r,e| !r.collect { |l| l.id }.include?(e.id) }

    # perform a few sanity checks on location / update any attributes needing it
    on(:added)   { |loc| check_location(nloc)}
    on(:updated) { |loc,oloc| check_location(nloc,oloc)}

    # setup parent when entity is added or updated
    on(:added)   { |loc| adjust_heirarchry(loc) }
    on(:updated) { |nloc,oloc| adjust_heirarchry(nloc,oloc) }

    # setup location callbacks
    on(LOCATION_EVENTS) { |loc, evnt, *args|
      loc.raise_event(evnt, *args)
    }

    # start location runner
    run { run_locations }
  end

end # module motel
