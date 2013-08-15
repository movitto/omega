# Users module stats attributes
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

module Attributes

# Number of ships destroyed by the user
class ShipsUserDestroyed < Users::AttributeClass
  id           :ships_user_destroyed
  description  "Number of ships the user destroyed"
  callbacks    :level_up  =>
    lambda { |attr|
      attr.user.update_attribute!(EntityManagementLevel.id, 0.1)
      attr.user.update_attribute!(OffenseLevel.id, 0.1)
      attr.user.update_attribute!(DefenseLevel.id, 0.1)
    }
end

# Number of times a user ship was destroyed
class UserShipsDestroyed < Users::AttributeClass
  id           :user_ships_destoryed
  description  "Number of the user's ships that were destroyed"
  callbacks    :level_up  =>
    lambda { |attr|
      attr.user.update_attribute!(EntityManagementLevel.id, -0.1)
      attr.user.update_attribute!(OffenseLevel.id, -0.1)
      attr.user.update_attribute!(DefenseLevel.id, -0.1)
    }
end

# Records total distance a user has travelled
class DistanceTravelled < Users::AttributeClass
  id          :distance_travelled
  description "Total distance user traveled"

  callbacks    :level_up  =>
    lambda { |attr|
      attr.user.update_attribute!(PilotLevel.id, 0.001)
    }
end

# Total amount of loot user collected
class LootCollected < Users::AttributeClass
  id          :loot_collected
  description "Total amount of loot collected"
end

# Total number of resources a user has collected
class ResourcesCollected < Users::AttributeClass
  id          :resources_collected
  description "Total amount of resources collected"
  callbacks    :level_up  =>
    lambda { |attr|
      attr.user.update_attribute!(MiningLevel.id, 0.1)
    }
end

# Total number of missions user successfully completed
class MissionsCompleted < Users::AttributeClass
  id          :missions_completed
  description "Total number of missions user successfully completed"
  callbacks    :level_up  =>
    lambda { |attr|
      attr.user.update_attribute!(MissionAgentLevel.id, 0.1)
    }
end

# Total number of missions user failed
class MissionsFailed < Users::AttributeClass
  id          :missions_failed
  description "Total number of missions user failed"
  callbacks    :level_up  =>
    lambda { |attr|
      attr.user.update_attribute!(MissionAgentLevel.id, -0.1)
    }
end

end
end
