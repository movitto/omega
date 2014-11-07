# Omega Client ProximityDetection Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module ProximityDetection
      def self.included(base)
        # Run proximity checks via an external thread for all entities
        # upon first entity initialization
        #
        # TODO share thread / tracker objs across all classes
        base.entity_init { |entity|
          @@entities ||= []
          @@entities << entity

          @@proximity_thread ||= Thread.new {
            while true
              @@entities.each { |e|
                e.check_proximity
              }
              sleep 10
            end
          }
        }
      end

      # Check nearby locations, if enemy ship is detected
      # stop movement and attack it. Result patrol route when attack ceases
      def check_proximity
        solar_system.entities.each { |e|
          if trigger_proximity?(e)
            proximity_triggered!(e)
            break
          end
        } unless skip_proximity_check?
      end
    end # module ProximityDetection
  end # module Client
end # module Omega
