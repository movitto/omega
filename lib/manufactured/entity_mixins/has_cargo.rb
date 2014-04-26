# Manufactured HasCargo Entity Mixin
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/resource'
require 'omega/constraints'

module Manufactured
module Entity
  # Mixin indicating entity has cargo
  #
  # Assumes 'id' and 'location' properties are accessible
  module HasCargo
    include Omega::ConstrainedAttributes

    def self.included(base)
      base.inherit_constraints self
    end

    # @!group Looting Properties

    # Max distance ship may be from loot to collect it
    constrained_attr :collection_distance

    # @!endgroup

    # List of resources contained in the entity
    attr_accessor :resources

    # @!group Cargo Properties

    # Max cargo capacity of entity
    # @see #cargo_quantity
    constrained_attr :cargo_capacity

    # @!endgroup

    # @!group Transfer properties

    # Max distance ship may be away from a target to transfer to it
    constrained_attr :transfer_distance

    # @!endgroup

    # Initialize cargo properties from args
    def cargo_from_args(args)
      attr_from_args args, :resources => []
    end

    # Return cargo attributes which are updatable
    def updatable_cargo_attrs
      @updatable_cargo_attributes ||= [:resources]
    end

    def cargo_empty?
      cargo_quantity == 0
    end

    def cargo_full?
      cargo_quantity >= cargo_capacity
    end

    def cargo_space
      cargo_capacity - cargo_quantity
    end

    # Return bool indicating if resources are valid
    def resources_valid?
      @resources.is_a?(Array) &&
      @resources.select { |r|
        !r.is_a?(Cosmos::Resource)
      }.empty? # TODO verify resources are valid in context of entity
    end

    # Add resource locally
    #
    # @param [Resource] resource to add
    # @raise [RuntimeError] if entity cannot accept resource
    def add_resource(resource)
      raise RuntimeError,
            "entity cannot accept resource" unless can_accept?(resource)
      res = @resources.find { |r| r.material_id == resource.material_id }
      if res.nil?
        resource.entity = self
        @resources << resource
      else
        res.quantity += resource.quantity
      end
      nil
    end

    # Remove specified quantity of resource specified by material id from entity
    #
    # @param [Resource] resource to remove
    # @raise [RuntimeError] if resource cannot be removed
    def remove_resource(resource)
      res = @resources.find { |r|
        r.material_id == resource.material_id &&
        r.quantity >= resource.quantity
      }
      raise RuntimeError,
            "entity does not contain specified resource" if res.nil?

      if res.quantity == resource.quantity
        @resources.delete(res)
      else
        res.quantity -= resource.quantity
      end
      nil
    end

    # Determine the current cargo quantity
    #
    # @return [Integer] representing the amount of resource/etc in the entity
    def cargo_quantity
      @resources.inject(0) { |t,r| t+= r.quantity }
    end

    # Return boolean if entity can transfer specified quantity of resource
    # specified by material_id to specified destination
    #
    # @param [Manufactured::Entity] to_entity entity which resource is being transfered to
    # @param [Resource] resource being transfered
    def can_transfer?(to_entity, resource)
      res =
        @resources.find { |r|
          r.material_id == resource.material_id &&
          r.quantity >= resource.quantity
        }

      same_entity =
        id == to_entity.id

      same_system =
        (location.parent_id == to_entity.location.parent_id)

      close_enough =
        ((location - to_entity.location) <= transfer_distance)

      !same_entity && !res.nil? && same_system &&  close_enough
    end

    # Return boolean indicating if entity can accpt the specified quantity
    # of the resource specified by id
    #
    # @param [Resource] resource being transferred
    def can_accept?(resource, quantity=resource.quantity)
      alive? && ((cargo_quantity + quantity) <= cargo_capacity)
    end

    # Return cargo attributes in json format
    def cargo_json
      {:cargo_capacity    => @cargo_capacity,
       :transfer_distance => @transfer_distance,
       :resources         => @resources}
    end
  end # module HasCargo
end # module Entity
end # module Manufactured
