# Omega TrackEntity Client Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module TrackEntity
      # The class methods below will be defined on the
      # class including this module
      #
      # @see ClassMethods
      def self.included(base)
        @entities ||= []

        base.extend(ClassMethods)

        # On initialization register entities w/ registry,
        # deleting old entity if it exists
        base.entity_init { |e|
          TrackEntity.track_entity e
        }
      end

      # Instance wrapper around class.entities
      def entities
        self.class.entities
      end

      # Track specified entity
      def self.track_entity(e)
        o = @entities.find { |re| re.id == e.id }
        @entities.delete(o) unless o.nil?
        @entities << e
      end

      # Return all entities in all classes w/ TrackEntity.entities
      def self.entities
        @entities
      end

      # Clear all entities
      def self.clear_entities
        @entities = []
      end

      # Methods that are defined on the class including
      # the TrackState module
      module ClassMethods
        # Return all entities of the local type
        def entities
          TrackEntity.entities.select { |e| e.kind_of?(self) }
        end

        # Only clear entities on the local type
        def clear_entities
          le = entities
          TrackEntity.entities.reject! { |e| le.include?(e) }
        end

        # Refresh all entities
        def refresh
          entities.each { |e| e.refresh }
        end

        # Return cached entity, else retrieve
        def cached(id)
          e = entities.find { |e| e.id == id }
          return e unless e.nil?
          self.get id
        end
      end
    end # module TrackEntity
  end # module Client
end # module Omega
