# stats::get rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'stats/registry'
require 'stats/rjr/init'

# TODO batch stats retrieval mechanism

module Stats::RJR
# retrieve stats filtered by args
get_stats = proc { |*args|
  # TODO support non-id filters
  stat_id = args.shift

  # TODO permissions on particular stats?
  #   (perhaps stats themselves can specify if
  #    they require more restricted access?)
  require_privilege(:registry => user_registry,
                    :privilege => 'view', :entity => "stats")

  stat = Stats.get_stat(stat_id)
  raise Omega::DataNotFound, "stat specified by #{stat_id} not found" if stat.nil?
  stat.generate *args
}

GET_METHODS = { :get_stats => get_stats }
end

def dispatch_stats_rjr_get(dispatcher)
  m = Stats::RJR::GET_METHODS
  dispatcher.handle 'stats::get', &m[:get_stats]
end
