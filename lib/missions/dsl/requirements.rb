# Mission Requirements DSL
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'missions/dsl/helpers'

module Missions
module DSL

# Mission Requirements
module Requirements
  include Helpers

  # Ensure both mission owner and user its being assigned to have at least one
  # ship docked at a common station
  def self.shared_station
    proc { |mission, assigning_to|
      # ensure users have a ship docked at a common station
      created_by = mission.creator
      centities  = node.invoke('manufactured::get_entities',
                               'of_type', 'Manufactured::Ship',
                               'owned_by', created_by.id)
      cstats     = centities.collect { |s| s.docked_at_id }.compact

      aentities  = node.invoke('manufactured::get_entities',
                               'of_type', 'Manufactured::Ship',
                               'owned_by', assigning_to.id)
      astats     = aentities.collect { |s| s.docked_at_id }.compact

      !(cstats & astats).empty?
    }
  end

  # Ensure user mission is being assigned to has a ship at the specified station
  def self.docked_at(station)
    proc { |mission, assigning_to|
      # ensure user has ship docked at specified station
      aentities  = node.invoke('manufactured::get_entities',
                               'of_type', 'Manufactured::Ship',
                               'owned_by', assigning_to.id)
      astats     = aentities.collect { |s| s.docked_at_id }.compact

      astats.include?(station.id)
    }
  end

end # module Requirements
end # module DSL
end # module Missions
