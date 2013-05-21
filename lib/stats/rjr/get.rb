# stats::get rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

get_stats = proc { |*args|
  # TODO support non-id filters
  stat_id = args.shift

  # TODO permissions on particular stats? (perhaps stats themselves can specify if they require more restricted access?)
  Users::Registry.require_privilege(:privilege => 'view', :entity => "stats",
                                    :session => @headers['session_id'])

  stat = Stats::Registry.instance.get(stat_id)
  raise Omega::DataNotFound, "stat specified by #{stat_id} not found" if stat.nil?
  stat.generate *args
}

def dispatch_get(dispatcher)
  dispatcher.handle 'stats::get', &get_stats
end
