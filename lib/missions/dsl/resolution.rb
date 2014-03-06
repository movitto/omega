# Mission Resolution DSL
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'missions/dsl/helpers'
require 'users/attributes/stats'

module Missions
module DSL

# Mission Resolution
module Resolution
  include Helpers

  # Add resource to a user owned entity
  def self.add_reward(rs)
    proc { |mission|
      # TODO better way to get user ship than this
      # TODO try other ships if add_resource fails
      entity = Query.user_ships.call(mission).first

      # add resources to player's cargo
      rs.id = Motel.gen_uuid
      rs.entity = entity
      node.invoke('manufactured::add_resource', entity.id, rs)
    }
  end

  # Updates mission-related user attributes
  def self.update_user_attributes
    proc { |mission|
      # update user attributes
      atr = mission.victorious ? Users::Attributes::MissionsCompleted.id :
                                 Users::Attributes::MissionsFailed.id
      node.invoke('users::update_attribute',
                                 mission.assigned_to_id,
                                 atr, 1)
    }
  end

  # Cleanup all entity events related to the mission
  def self.cleanup_entity_events(id, *evnts)
    proc { |mission|
      entities = mission.mission_data[id]
      entities = [entities] unless entities.is_a?(Array)

      entities.each { |entity|
        # remove callbacks
        node.invoke('manufactured::remove_callbacks', entity.id)

        # remove event handlers
        evnts.each { |evnt|
          eid = Missions::Events::Manufactured.gen_id(entity.id, evnt)
          registry.cleanup_event(eid)
        }
      }
    }
  end

  # Cleanup mission expiration event
  def self.cleanup_expiration_events
    proc { |mission|
      # remove expiration event
      eid = "mission-#{mission.id}-expired"
      registry.cleanup_event(eid)
    }
  end

  # Recycle mission, eg clone it w/ a new id, clear assignment,
  # and add it to the registry
  def self.recycle_mission
    proc { |mission|
      # create a new mission based on the specified one
      new_mission = mission.clone :id => Motel.gen_uuid
      new_mission.clear_assignment!
      node.invoke('missions::create_mission', new_mission)
    }
  end

end # module Resolution
end # Module DSL
end # Module Missions
