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
      entity_validation { |e| e.type == :manufacturing }

      entity_event \
        :construction_complete =>
          {:subscribe    => "manufactured::subscribe_to",
           :notification => "manufactured::event_occurred",
           :match => proc { |entity,*a|
             a[0] == 'construction_complete' && a[1].id == entity.id
           }},

        :partial_construction  =>
          {:subscribe    => "manufactured::subscribe_to",
           :notification => "manufactured::event_occurred",
           :match => proc { |entity, *a|
             a[0] == 'partial_construction' && a[1].id == entity.id
           }},

        :construction_failed  =>
          {:subscribe    => "manufactured::subscribe_to",
           :notification => "manufactured::event_occurred",
           :match => proc { |entity, *a|
             a[0] == 'construction_failed' && a[1].id == entity.id
           }}


      # Construct the specified entity on the server
      #
      # All server side construction restrictions apply, this method does
      # not do any checks b4 invoking construct_entity so if server raises
      # a related error, it will be reraised here
      #
      # Raises the :constructed event on self
      #
      # @param [Hash] args hash of args to be converted to array and passed to
      #   server construction operation verbatim
      def construct(args={})
        RJR::Logger.info "Constructing #{args} with #{self.entity.id}"
        constructed = node.invoke 'manufactured::construct_entity',
                          self.entity.id, *(args.to_a.flatten)
        raise_event(:constructed, constructed)
        constructed
      end

      # Get/set the type of entity to construct using this station
      def entity_type(val=nil)
        @entity_type = val unless val.nil?
        @entity_type
      end
      alias :entity_type= :entity_type

      # Start the omega client bot
      def start_bot
        start_construction
        handle(:transferred_from) { |*args|
          start_construction
        }
      end

      # Begin construction cycle
      def start_construction
        entity = construction_args.merge({ :id => gen_uuid })
        construct entity if can_construct?(entity)
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
    end
  end # module Client
end # module Omega
