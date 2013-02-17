# The Stopped MovementStrategy model definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'
require 'motel/movement_strategy'

module Motel
module MovementStrategies

# Stopped is the default MovementStrategy which does nothing 
class Stopped < MovementStrategy
   include Singleton

   def to_s
     "stopped"
   end

   # Return stopped movement strategy singleton instance
   def self.json_create(o)
     self.instance
   end
end

end # module MovementStrategies
end # module Motel
