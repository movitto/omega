# Exceptions used in the MOTEL project
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Motel

# Error raised by the {Motel::Runner} and other subsystems
# when a movement strategy is invalid in its context
class InvalidMovementStrategy  < RuntimeError
   def initialize(msg)
      super(msg)
   end
end

end
