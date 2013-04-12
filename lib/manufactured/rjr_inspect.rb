# RJR method definitions providing access to inspect the state
# of the internal manufactured subsystems
#
# Note this isn't included in the top level manufactured module by default,
# manually include this module to incorporate these additional rjr method
# definitions into your node
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/util'

include RJR::Definitions

rjr_method \
  "manufactured::status" =>
    # Retrieve the overall status of this node
    lambda {
      {
        # registry
        :registry => { :running   => Manufactured::Registry.instance.running?,
                       :num_ships => Manufactured::Registry.instance.ships.size,
                       :num_stations => Manufactured::Registry.instance.stations.size }
        # TODO loot, ship graveyard, commands etc
      }
    }
