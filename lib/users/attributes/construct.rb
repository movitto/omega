# Users module interaction attributes
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

module Attributes

# permits user to construct entities of a specific type
class ConstructionClass < Users::AttributeClass
end

# permits users to construct a specified number of entities at a time
class ParallelConstruction < Users::AttributeClass
end

end
end
