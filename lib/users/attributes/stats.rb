# Users module stats attributes
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

module Attributes

# Number of ships destroyed by the user
class ShipsUserDestroyed < Users::AttributeClass
  id           :ships_user_destroyed
  description  "The number of ships the user destroyed"
  callbacks    :level_up  => lambda { |attr|
                               attr.user.update_attribute!(NumberOfShips.id, 0.1)
                             }
end

# Number of times a user ship was destroyed
class UserShipsDestroyed < Users::AttributeClass
  id           :user_ships_destoryed
  description  "The number of the user's ships that were destroyed"
  callbacks    :level_up  => lambda { |attr|
                               attr.user.update_attribute!(NumberOfShips.id, -0.1)
                             }
end

end
end
