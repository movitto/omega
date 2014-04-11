# manufactured::create_entity attribute helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/attributes/interact'

module Manufactured::RJR
  # Helper to modify base ship attributes from user attributes
  def set_entity_attributes(entity, user)
    # entity attribute |          user attribute           | scale
    [[:movement_speed,   Users::Attributes::PilotLevel.id,   20],
     [:damage_dealt,     Users::Attributes::OffenseLevel.id, 10],
     [:max_shield_level, Users::Attributes::DefenseLevel.id, 10],
     [:mining_quantity,  Users::Attributes::MiningLevel.id,  10]].each { |p,a,l|
       entity.send("#{p}+=".intern,
                   user.attribute(a).level / l) if user.has_attribute?(a)
     } if entity.is_a?(Ship)
  end
end # module Manufactured::RJR
