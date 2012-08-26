# Exceptions used in the MOTEL project
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Motel

class InvalidMovementStrategy  < RuntimeError
   def initialize(msg)
      super(msg)
   end
end

end
