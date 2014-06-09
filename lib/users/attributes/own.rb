# Users module ownership attributes
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Users

module Attributes

# Controls number of entities a user may own and max level which
# they may be upgraded to
class EntityManagementLevel < Users::AttributeClass
  id           :number_of_entities
  description  "Competency at managing user controlled entities"
  multiplier   3
  callbacks    :level_up  =>
    lambda { |attr|
      attr.user.update_attribute!(EntityClass.id, 0.1)
    },
               :level_down =>
    lambda { |attr|
      attr.user.update_attribute!(EntityClass.id, -0.1)
    }

end

# Permits a user to own a entities of a specified type
# TODO needs to be parameterized
class EntityClass < Users::AttributeClass
  id          :entity_class
  description ""
end

end
end
