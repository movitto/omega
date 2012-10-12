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
              # we delete the handler after one invocation, forcing the client to
              # reregister a movement handler
              # XXX if original handler registers another though, we are still susceptible
              # to more on_movement notifications which may have come in in the meantime,
              # it might make sense to delete the callback upon invocation on the server
              # side (see comment in lib/motel/runner::run_cycle)
              handler = Tracker.synchronize { @@movement_handlers.delete(loc.id) }
              @@event_queue << [handler, [loc]]
            }
          end
        }

        @@event_timer ||= self.class.schedule_event_cycle

        Tracker.invoke_request 'motel::track_movement', @entity.id, distance
      end

    end
  end
end
