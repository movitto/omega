# Users module interaction attributes
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

module Attributes

# Increases base movement speed of owned entities
class PilotLevel < Users::AttributeClass
  id          :pilot_level
  description "Competency at piloting entities"
end

# Controls base offensive attributes such as damade dealt
# and number of targers
class OffenseLevel < Users::AttributeClass
  id           :offense_level
  description  "Competency at offensive capabilities"
end

# Controls base defensive attributes such as hp and shield level
class DefenseLevel < Users::AttributeClass
  id           :defense_level
  description  "Competency at defensive capabilities"
end

# Controls base mining attributes such as resource collection rate
class MiningLevel < Users::AttributeClass
  id           :mining_level
  description  "Competency at resource collection capabilities"
end

# Controls types of resources which user may mine
# TODO not level based, need boolean(s) w/ metadata
class MiningCapability < Users::AttributeClass
end

# Controls base construction attributes such as number of entities
# able to be constructed in parallel
class ConstructionLevel < Users::AttributeClass
  id           :construction_level
  description  "Competency at manufacturing capabilities"
end

# TODO attribute to enable or limit amount / type of loot collected ?

end
end
