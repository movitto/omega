# Motel Sanitizes Locations Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/movement_strategies/follow'
require 'motel/movement_strategies/stopped'

module Motel
module SanitizesLocations
  # Perform a few sanity checks on location / update any attributes needing it.
  def sanitize_location(nloc, oloc=nil)
    changing = stopping = false

    # if follow movement strategy, update location from tracked_location_id
    if nloc.ms.is_a?(MovementStrategies::Follow)
      tracked = @entities.find { |l| l.id == nloc.ms.tracked_location_id }
      nloc.ms.tracked_location = tracked
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

    nloc.raise_event(:changed_strategy) if changing
    nloc.raise_event(:stopped) if stopping
  end
end # module SanitizesLocations
end # module Motel
