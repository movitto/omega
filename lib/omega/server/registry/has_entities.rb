# Base Registry HasEntities Mixin
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/util/json_parser'

module Omega
module Server
module Registry
  module HasEntities
    attr_accessor :validation_methods

    # Add validation method to registry
    def validation_callback(&bl)
      @validation_methods << bl
    end

    attr_accessor :retrieval

    def init_entities
      @entities  ||= []
      @retrieval ||= proc { |e| }
      @validation_methods ||= []
    end

    # TODO an 'old_entities' tracker where clients may put items
    # which should be retired from active operation

    # Return entities for which selector proc returns true
    #
    # Note only copies of entities will be returned, not the
    # actual entities themselves
    def entities(&select)
      init_registry
      @lock.synchronize {
        # by default return everything
        select = proc { |e| true } if select.nil?

        # registry entities
        rentities = @entities.select(&select)

        # invoke retrieval to update each registry entity
        rentities.each { |r| @retrieval.call(r) }

        # we use json serialization to perform a deep clone
        result = Array.new(RJR::JSONParser.parse(rentities.to_json))

        result
      }
    end

    # Return first entity which selector proc returns true
    def entity(&select)
      entities(&select).first
    end

    # Clear all entities tracked by local registry
    def clear!
      init_registry
      @lock.synchronize {
        @entities = []
      }
    end

    # Add entity to local registry.
    #
    # Invokes registered validation callbacks before
    # adding to ensure enitity should be added. If
    # any validation returns false, entity will not be
    # added.
    #
    # Raises :added event on self w/ entity
    def <<(entity)
      init_registry
      added  = false
      cloned = nil
      @lock.synchronize {
        added = @validation_methods.all? { |v| v.call(@entities, entity) }
        if added
          @entities << entity
          cloned = RJR::JSONParser.parse(entity.to_json)
        end
      }

      raise_event(:added, cloned) if added
      added
    end

    # Remove entity from local registry. Entity removed
    # will be first entity for which selector returns true.
    #
    # Raises :delete event on self w/ deleted entity
    def delete(&selector)
      init_registry
      delete = false
      @lock.synchronize {
        entity = @entities.find(&selector)
        delete = !entity.nil?
        @entities.delete(entity) if delete
      }
      raise_event(:deleted, entity) if delete
      delete
    end

    # Update entity in local registry.
    #
    # Entity updated will be first entity for which the
    # selector proc returns true. The entity being
    # updated must define the 'update' method which
    # takes another entity which to copy attributes from/etc.
    #
    # Raises :updated event on self with updated entity
    def update(entity, &selector)
      # TODO default selector ? (such as with_id)
      init_registry
      orig = cloned = nil
      found = false
      @lock.synchronize {
        # select entity from registry
        rentity = @entities.find &selector
        found   = !rentity.nil?

        if found
          orig = RJR::JSONParser.parse(rentity.to_json)
          rentity.update(entity)
          cloned = RJR::JSONParser.parse(rentity.to_json)
        end
      }

      # TODO make sure proxy operations are kept in sync w/ update operations
      #   (see proxy_for below and ProxyEntity definition)
      raise_event(:updated, cloned, orig) if found
      found
    end
  end # module HasEntities
end # module Registry
end # module Server
end # module Omega
