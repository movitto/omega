# Missions Failed Event definition
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'missions/events/mission'

module Missions
module Events

# Spawned by the local missions subsystem upon mission failure
class Failed < MissionEvent
  def type
    'failed'
  end

  # Handle event
  def handle_event
    mission.failed!
    update_mission
  end

end # class Failed
end # module Events
end # modjule Missions
