# Omega Client Factory Tracker
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/entities/station'
require 'omega/client/entities/solar_system'

module Omega
  module Client
    # Omega Client Manufacturing Station Tracker
    class Factory < Station
      include ConstructionCapabilities

      entity_validation { |e| e.type == :manufacturing }

      # Generate construction args from entity type
      def construction_args
        case @entity_type
          when 'factory' then
            {:entity_type => 'Station',
             :type  => :manufacturing}
          when 'miner' then
            {:entity_type => 'Ship',
             :type  => :mining}
          when 'corvette' then
            {:entity_type => 'Ship',
             :type  => :corvette}
          else {}
        end
      end

      # Start the omega client bot
      def start_bot
        start_construction
        handle(:transferred_from) { |*args|
          start_construction
        }
      end

      # Pick system with no stations or the fewest stations and jump to it
      def pick_system
        # TODO optimize
        system = SolarSystem.get(system_id).
                             closest_neighbor_with_no :type => "Manufactured::Station",
                                                      :owned_by => user_id
        system = SolarSystem.with_fewest :type => "Manufactured::Station",
                                         :owned_by => user_id if system.nil?
        jump_to(system) if system.id != system_id
      end
    end
  end # module Client
end # module Omega
