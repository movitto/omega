# Motel Constants
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel
  LOCATION_EVENTS = [:movement, :rotation, :proximity, :stopped, :changed_strategy]

  CLOSE_ENOUGH            =  0.0001
  MAJOR_CARTESIAN_AXIS    = [1, 0, 0]
  MINOR_CARTESIAN_AXIS    = [0, 1, 0]
  CARTESIAN_NORMAL_VECTOR = [0, 0, 1]
end # module Motel
