# Users module interaction attributes
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

module Attributes

# Permits a user to attack entities and modifies attack related
# attributes in other subsystems
class Attack < Users::AttributeClass
end

# Permits a user to mine resources and modifies mining related
# attributes in other subsystems
class Mining < Users::AttributeClass
end

end
end
