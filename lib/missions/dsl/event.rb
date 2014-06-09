# Mission Events DSL
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'missions/dsl/helpers'

module Missions
module DSL

# Mission related events handlers
module Event
  include Helpers

  def self.resource_collected
    proc { |mission, evnt|
      rs = evnt.manufactured_event_args[2].material_id
      q  = evnt.manufactured_event_args[3]
      mission.mission_data['resources']     ||= {}
      mission.mission_data['resources'][rs] ||= 0
      mission.mission_data['resources'][rs]  += q
      update_mission mission

      if Query.check_mining_quantity.call(mission)
        Event.create_victory_event.call(mission, evnt)
      end
    }
  end

  def self.transferred_out
    proc { |mission, evnt|
      dst = evnt.manufactured_event_args[2]
      rs  = evnt.manufactured_event_args[3]
      mission.mission_data['last_transfer'] =
        { 'dst' => dst, 'rs' => rs.material_id, 'q' => rs.quantity }
      update_mission mission

      if Query.check_transfer.call(mission)
        Event.create_victory_event.call(mission, evnt)
      end
    }
  end

  def self.entity_destroyed
    proc { |mission, evnt|
      mission.mission_data['destroyed'] ||= []
      mission.mission_data['destroyed'] << evnt
      update_mission mission
    }
  end

  def self.collected_loot
    proc { |mission, evnt|
      loot = evnt.manufactured_event_args[2]
      mission.mission_data['loot'] ||= []
      mission.mission_data['loot'] << loot
      update_mission mission

      if Query.check_loot.call(mission)
        Event.create_victory_event.call(mission, evnt)
      end
    }
  end

  def self.check_victory_conditions
    proc { |mission, evnt|
      create_victory_event.call(mission, evnt) if mission.completed?
    }
  end

  def self.create_victory_event
    proc { |mission, evnt|
      # TODO unless mission.failed?
      victory  = Missions::Events::Victory.new :mission  => mission,
                                               :registry => registry
      registry << victory
    }
  end
end # module Event
end # module DSL
end # module Missions
