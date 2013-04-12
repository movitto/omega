# RJR method definitions providing access to inspect the state
# of the internal motel subsystems
#
# Note this isn't included in the top level motel module by default,
# manually include this module to incorporate these additional rjr method
# definitions into your node
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/util'

include RJR::Definitions

rjr_method \
  "motel::status" =>
    # Retrieve the overall status of this node
    lambda {
      {
        # runner
        :runner => { :running => Motel::Runner.instance.running?,
                     :num_locations => Motel::Runner.instance.locations.size,
                     :errors  => Motel::Runner.instance.errors }
      }
    }
