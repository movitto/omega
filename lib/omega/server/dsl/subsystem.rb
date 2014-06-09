# Omega Server Subsystem DSL operations
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Server
    module DSL
      # Return subsystem which request is running in.
      #
      # Extracts from rjr environment, assumes all Omega
      # RJR requests are served in the <subsystem>::RJR
      # environment.
      def subsystem
        rjr_env.parent
      end

      # Return bool indicating if event type corresponds to a subsystem event
      def subsystem_event?(event_type)
        subsystem::Events.module_classes.any? { |event_class|
          event_class::TYPE.to_s == event_type.to_s
        }
      end

      # Return bool indicating if entity is defined is the specified subsystem
      def subsystem_entity?(entity, subsys=nil)
        subsys = subsystem if subsys.nil?
        entity_class = entity.class
        entity_class = entity_class.parent until entity_class.parent == subsys ||
                                                 entity_class.parent == Object
        (entity_class.parent == subsys)
      end

      # Return bool indicating if entity is defined under Cosmos::Entities
      def cosmos_entity?(entity)
        subsystem_entity?(entity, Cosmos::Entities)
      end

    end # module DSL
  end # module Server
end # module Omega
