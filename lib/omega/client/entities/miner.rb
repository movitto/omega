# Omega Client Miner Tracker
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/entities/ship'

module Omega
  module Client
    # Omega Client Miner Tracker
    class Miner < Ship
      include CollectsResources
      include OffloadsResources

      entity_validation { |e| e.type == :mining }

      # Start the omega client bot
      def start_bot
        # start listening for events which may trigger state changes
        handle(:resource_collected)
        handle(:mining_stopped) { |m,*args|
          m.select_mining_target if args[3] != 'ship_cargo_full'
        }

        if cargo_full?
          offload_resources
        else
          select_mining_target
        end
      end
    end # class Miner
  end # module Client
end # module Omega
