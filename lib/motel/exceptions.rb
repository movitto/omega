# Exceptions used in the MOTEL project
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Motel

class InvalidMovementStrategy  < RuntimeError
   def initialize(msg)
      super(msg)
   end
end

end
