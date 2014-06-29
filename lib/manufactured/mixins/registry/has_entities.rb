# Manufactured Registry Has Entities Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'motel/movement_strategies/stopped'

module Manufactured
module HasEntities
  # Return array of ships tracked by registry
  def ships
    entities.select { |e| e.is_a?(Ship)    }
  end

  # Return array of stations tracked by registry
  def stations
    entities.select { |e| e.is_a?(Station) }
  end

  # Return array of loot tracked by registry
  def loot
    entities.select { |e| e.is_a?(Loot)    }
  end
end # module HasEntities
end # module Manufactured
