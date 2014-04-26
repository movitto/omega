# Manufactured ConstructionCapabilities Entity Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/constraints'

module Manufactured
module Entity
  module ConstructionCapabilities
    include Omega::ConstrainedAttributes

    def self.included(base)
      base.inherit_constraints self
    end

    # Distance away from the station which new entities are constructed
    constrained_attr :construction_distance

    # Return true / false indiciating if station can construct entity specified by args.
    #
    # @param [Hash] args args which will be passed to {#construct} to construct entity
    # @return [true,false] indicating if station can construct entity
    def can_construct?(args = {})
      @type == :manufacturing &&

      ['Ship', 'Station'].include?(args[:entity_type]) &&

      cargo_quantity >=
        Manufactured.const_get(args[:entity_type]).construction_cost
    end

    # Use this station to construct new manufactured entities.
    #
    # Sets up the entity in the correct context, including the right
    # location properties and verifies its validitiy before deducting
    # resources necessary to construct and instanting new entity.
    #
    # @param [Hash] args hash of options to pass to new entity being initialized
    # @return new entity created, nil otherwise
    def construct(args = {})
      # return if we can't construct
      return nil unless can_construct?(args)

      # grab handle to entity class & generate construction cost
      eclass = Manufactured.const_get(args[:entity_type])
      ecost  = eclass.construction_cost

      # remove resources from the station
      # TODO map entities to specific construction requirements
      remaining = ecost
      @resources.each { |r|
        if r.quantity > remaining
          r.quantity -= remaining
          break
        else
          remaining -= r.quantity
          @resources.delete(r)
        end
      }

      # instantiate the new entity
      entity = eclass.new args
      entity.location.parent = self.location.parent

      # setup location
      entity.parent = self.parent

      # allow user to specify coordinates unless too far away
      # in which case, construct at closest location to specified
      # location withing construction distance
      distance = entity.location - self.location
      if distance > construction_distance
        dx = (entity.location.x - self.location.x) / distance
        dy = (entity.location.y - self.location.y) / distance
        dz = (entity.location.z - self.location.z) / distance
        entity.location.x = self.location.x + dx * construction_distance
        entity.location.y = self.location.y + dy * construction_distance
        entity.location.z = self.location.z + dz * construction_distance
      end
      # TODO introduce optional random element that can be added to entity location ?

      entity
    end
  end # module ConstructionCapabilities
end # module Entity
end # module Manufactured
