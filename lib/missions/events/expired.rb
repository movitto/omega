# Missions Expired Event definition
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'missions/events/mission'

module Missions
module Events

# Spawned by the local missions subsystem upon mission expiration
class Expired < MissionEvent
  def type
    'expired'
  end

  # Handle event
  def handle_event
    mission.failed! # if mission.expired? && !mission.completed? TODO?
    update_mission
  end

end # class Expired
end # module Events
end # modjule Missions
