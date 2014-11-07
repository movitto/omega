# Omega Client Corvette Tracker
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'omega/client/entities/ship'

module Omega
  module Client
    # Omega client corvette ship tracker
    class Corvette < Ship
      include OffenseCapabilities
      include ProximityDetection
      include PatrolsRoute
      include SeeksTarget

      entity_validation { |e| e.type == :corvette }

      # Mode should be :patrol or :seek_and_destroy
      attr_accessor :mode

      # True if mode is not set or when patroling
      def passive?
        mode.nil? || mode == :patrol
      end

      ####################################### ProximityDetection

      def skip_proximity_check?
        !passive? || !alive? || attacking?
      end

      def trigger_proximity?(entity)
        entity.is_a?(Manufactured::Ship) && entity.user_id != user_id &&
        entity.location - location <= attack_distance && entity.alive?
      end

      def proximity_triggered!(entity)
        stop_moving
        attack(entity)
      end

      ####################################### SeeksTarget

      def avail_targets
        solar_system.entities
                    .select { |e| e.is_a?(Manufactured::Ship) && e.user_id != user_id }
                    .sort { |e1, e2| location.distance_from(e1.location) <=> location.distance_from(e2.location) }
      end

      #######################################


      # Start the omega client bot
      def start_bot
        handle(:destroyed_by)

        if passive?
          handle(:attacked_stop){ |*args| patrol_route }
          patrol_route

        else # if active
          seek_and_destroy_all
        end
      end
    end # class Corvette
  end # module Client
end # module Omega
