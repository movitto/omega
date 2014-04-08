# Static stats registry
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Stats
################################################################

STATISTICS = []

def  self.get_stat(id)
  STATISTICS.find { |s| s.id.to_s == id.to_s}
end

def self.register_stat(stat)
  STATISTICS << stat
end

require 'stats/stat'
require 'stats/registry/universe_id'
require 'stats/registry/num_of'
require 'stats/registry/users_with_most'
require 'stats/registry/users_with_least'
require 'stats/registry/systems_with_most'

end # module Stats
