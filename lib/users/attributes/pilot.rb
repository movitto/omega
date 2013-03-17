# Users module piloting attributes
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

module Attributes

# Permits a user to pilot a specified number of ships
class NumberOfShips < Users::AttributeClass
  id          :number_of_ships
  description "Maximum number of ships a user may pilot"
  multiplier   3
end

# Permits a user to pilot a specified class of ship
class ShipClass < Users::AttributeClass
  id          :ship_class
  description ""
end

# Permits a user to pilot ships at a specified level TODO
#class ShipLevel < Users::AttributeClass
#end

end
end
