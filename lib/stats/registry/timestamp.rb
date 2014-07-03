# Server Timestamp Stamp
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Stats
  # Return current time
  universe_timestamp_proc = proc {
    Time.now.to_f
  }

  universe_timestamp =
    Stat.new(:id          => :universe_timestamp,
             :description => 'Current Universe Time',
             :generator   => universe_timestamp_proc)

  register_stat universe_timestamp
end # module Stats
