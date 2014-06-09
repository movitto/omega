# manufactured::move entity in system helper
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/move/ship_in_system'
require 'manufactured/rjr/move/station_in_system'

module Manufactured::RJR
  # Move entity in single system
  def move_entity_in_system(entity, loc)
    entity.is_a?(Ship) ?    move_ship_in_system(entity, loc) :
                         move_station_in_system(entity, loc)
  end
end
