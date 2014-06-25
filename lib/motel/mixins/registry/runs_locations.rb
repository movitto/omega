# Motel Runs Locations Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel
module RunsLocations

  def run_location(loc, elapsed)
    ::RJR::Logger.debug "runner moving location #{loc}"

    begin
      old_coords, old_orientation = nil, nil
      changing = stopping = false

      # operate on registry entity so that retrieval, movement,
      # and storage are atomic on latest location (which
      # may also be updated with motel::update_location)
      self.safe_exec { |locs|
        loc = locs.find { |l| l.id == loc.id }

        old_coords,old_orientation = loc.coordinates,loc.orientation

        loc.movement_strategy.move loc, elapsed
        loc.last_moved_at = Time.now

        if loc.movement_strategy.change?(loc)
          # TODO s/next_movement_strategy/next_movement_strategies, allow
          # a queue of movement strategies to be set
          loc.movement_strategy = loc.next_movement_strategy
          loc.next_movement_strategy = Motel::MovementStrategies::Stopped.instance
          changing = true
          stopping = loc.movement_strategy == Motel::MovementStrategies::Stopped.instance
          loc.reset_tracked_attributes

        end
      }

      # invoke movement and rotation callbacks
      # TODO invoke these async so as not to hold up the runner
      raise_event(:movement, loc, *old_coords)
      raise_event(:rotation, loc, *old_orientation)
      raise_event(:changed_strategy, loc) if changing
      raise_event(:stopped,          loc) if stopping

    rescue Exception => e
      ::RJR::Logger.warn "error running location/callbacks for #{loc.id}: #{e.to_s}"
      ::RJR::Logger.warn e.backtrace
    end
  end

  def run_locations
    moved = []; delay = nil
    self.entities { |loc| !loc.ms.is_a?(MovementStrategies::Stopped) }.
         each { |loc|
      sdelay = loc.movement_strategy.step_delay
      elapsed = loc.last_moved_at.nil? ? sdelay + 1 :
                Time.now - loc.last_moved_at

      if elapsed > sdelay
        moved << loc
        run_location(loc, elapsed)

      else
        remaining = sdelay - elapsed
        delay = remaining if delay.nil? || remaining < delay

      end
    }

    # invoke all proximity_callbacks afterwards
    moved.each { |loc|
      begin
        raise_event :proximity, loc
      rescue Exception => e
        ::RJR::Logger.warn "error running proximity callbacks: #{e.to_s}"
      end
    }

    delay
  end


end # module RunsLocations
end # module Motel
