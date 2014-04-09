# Omega Client Ship Tracker
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'omega/client/entities/location'
require 'omega/client/entities/cosmos'
require 'omega/client/entities/station'
require 'manufactured/ship'

module Omega
  module Client
    # Omega client Manufactured::Ship tracker
    class Ship
      include Trackable
      include TrackEntity
      include TrackState
      include HasLocation
      include InSystem
      include HasCargo

      entity_type  Manufactured::Ship

      get_method   "manufactured::get_entity"

      entity_event \
        :defended =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'defended' && a[1].id == entity.id },
            :update => proc { |entity, *a|
              entity.hp,entity.shield_level =
                a[1].hp, a[1].shield_level
            }},

        :defended_stop =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'defended_stop' && a[1].id == entity.id },
            :update => proc { |entity, *a|
              entity.hp,entity.shield_level =
                a[1].hp, a[1].shield_level
            }},

        :destroyed_by =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'destroyed' && a[1].id == entity.id },
            :update => proc { |entity, *a|
              entity.hp,entity.shield_level =
                a[1].hp, a[1].shield_level
            }}

      # automatically cleanup entity when destroyed
      server_state :destroyed,
        :check => lambda { |e| !e.alive? },
        :off   => lambda { |e| },
        :on    =>
          lambda { |e|
            # TODO remove rjr notifications
            e.clear_handlers
          }

      # Dock at the specified station
      def dock_to(station)
        RJR::Logger.info "Docking #{id} at #{station.id}"
        node.invoke 'manufactured::dock', id, station.id
      end

      # Undock
      def undock
        RJR::Logger.info "Unocking #{id}"
        node.invoke 'manufactured::undock', id
      end

      # Collect specified loot
      #
      # @param [Manufactured::Loot] loot loot which to collect
      def collect_loot(loot)
        RJR::Logger.info "Entity #{id} collecting loot #{loot.id}"
        @entity = node.invoke 'manufactured::collect_loot', id, loot.id
      end
    end
  end
end
