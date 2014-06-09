# Missions Victory Event definition
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'missions/events/mission'

module Missions
module Events

# Spawned by the local missions subsystem upon mission completion
class Victory < MissionEvent
  def type
    'victory'
  end

  # Handle event
  def handle_event
    mission.victory!
    update_mission
  end

end # class Victory
end # module Events
end # module Missions
