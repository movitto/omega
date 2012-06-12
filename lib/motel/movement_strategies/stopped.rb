# The Stopped MovementStrategy model definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
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
end

end # module MovementStrategies
end # module Motel
