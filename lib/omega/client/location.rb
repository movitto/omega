#!/usr/bin/ruby
# omega client location tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'

module Omega
  module Client
    class Location < Entity
      def self.get_method
        "motel::get_location"
      end

      def self.entity_type
        "Motel::Location"
      end

      def on_movement_of(distance, &bl)
        Tracker.synchronize{
          @@movement_handlers ||= {}
          @@movement_handlers[@entity.id] = bl

          unless @registered_movement
            @registered_movement = true
            RJR::Dispatcher.add_handler("motel::on_movement") { |loc|
              Omega::Client::Tracker[Omega::Client::Location.entity_type + '-' + loc.id.to_s].entity= loc
              handler = Tracker.synchronize { @@movement_handlers[loc.id] }
              handler.call loc
            }
          end
        }

        Tracker.invoke_request 'motel::track_movement', @entity.id, distance
      end

    end
  end
end
