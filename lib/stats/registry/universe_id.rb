# universe_id stat
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Stats
  # Return unique universe id
  universe_id_proc = proc {
    Stats::RJR.universe_id
  }
  
  universe_id = Stat.new(:id => :universe_id,
                         :description => 'Unique ID of the universe',
                         :generator   => universe_id_proc)

  register_stat universe_id
end # module Stats
