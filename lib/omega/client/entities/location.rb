#!/usr/bin/ruby
# omega client location tracker
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'motel/location'

module Omega
  module Client
    # Include the HasLocation module in classes to associate
    # instances of the class w/ a server side location.
    #
    # @example
    #   class Ship
    #     include Trackable
    #     include HasLocation
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #   end
    #
    #   s = Ship.get('ship1')
    #   s.handle_event(:movement) { |sh|
    #     puts "#{sh.id} moved to #{sh.location}"
    #   }
    module HasLocation

      # Return latest location
      #
      # @return [Motel::Location]
      def location
        node.invoke('motel::get_location', 'with_id', self.entity.location.id)
      end

      # The class methods below will be defined on the
      # class including this module
      #
      # Defines an event to track entity/location movement
      # which the client may optionally register a handler for
      #
      # @see ClassMethods
      def self.included(base)
        base.entity_event \
          :movement =>
            { :setup =>
                proc { |distance|
                  node.invoke("motel::track_movement",
                              self.entity.location.id, distance)
                },
              :notification => "motel::on_movement",
              :match =>
                proc { |entity,l|
                  entity.location.id == l.id
                },
              :update =>
                proc { |entity,l|
                  entity.entity.location = l
                }
            }
      end
    end # module HasLocation

  end # module  Client
end # module Omega
