# Motel Sanitizes Locations Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel
module SanitizesLocations
  def sanitize_location(nloc, oloc=nil)
    changing = stopping = false
    @lock.synchronize{
      # if follow movement strategy, update location from tracked_location_id
      if nloc.ms.is_a?(MovementStrategies::Follow)
        nloc.ms.tracked_location =
          @entities.find { |l|
            l.id == nloc.ms.tracked_location_id
          }
      end

      # if changing movement strategy
      if !oloc.nil? && oloc.ms != nloc.ms
        changing = true

        # if changing to stopped movement strategy
        stopping = nloc.ms.is_a?(MovementStrategies::Stopped)

        # reset last moved at
        nloc.last_moved_at = nil
        nloc.reset_tracked_attributes
      end
    }

    raise_event(:changed_strategy, nloc) if changing
    raise_event(:stopped, nloc) if stopping
  end
end # module SanitizesLocations
end # module Motel
