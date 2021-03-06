# Motel Runs Locations Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'motel/movement_strategies/stopped'

module Motel
module RunsLocations
  private

  def run_location(loc)
    ::RJR::Logger.debug "runner moving location #{loc}"

    orig_coords      = loc.coordinates
    orig_orientation = loc.orientation

    begin
      loc.movement_strategy.move loc, (loc.time_since_movement || 0)
    rescue => e
      ::RJR::Logger.warn "error running location #{loc.id}: #{e.to_s}"
      ::RJR::Logger.warn e.backtrace
      return
    end

    loc.last_moved_at = Time.now

    register_location_event loc, :movement, *orig_coords
    register_location_event loc, :rotation, *orig_orientation

    if loc.movement_strategy.change?(loc)
      # TODO allow a queue of movement strategies to be set (loc.ms = loc.ms.next_ms)
      loc.movement_strategy = loc.next_movement_strategy
      loc.next_movement_strategy = Motel::MovementStrategies::Stopped.instance

      register_location_event loc, :changed_strategy
      register_location_event loc, :stopped if loc.stopped?

      loc.reset_tracked_attributes
    end
  end

  def movable_locations
    @entities.select { |loc| !loc.stopped? }
  end

  def locations_to_move
    movable_locations.select { |loc| loc.should_move? }
  end

  def next_loc
    (movable_locations - locations_to_move).sort { |loc1, loc2|
      loc1.ms.step_delay <=> loc2.ms.step_delay
    }.first
  end

  def next_cycle_delay
    nl = next_loc
    nl ? nl.time_until_movement : nil
  end

  public

  def run_locations
    @lock.synchronize {
      locations_to_move.each { |loc|
        run_location loc
        register_location_event loc, :proximity
      }

      next_cycle_delay
    }
  end
end # module RunsLocations
end # module Motel
