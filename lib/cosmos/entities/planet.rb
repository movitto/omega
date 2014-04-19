# Cosmos Planet definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'
require 'motel/movement_strategies/elliptical'
require 'omega/constraints'

module Cosmos
module Entities

# http://en.wikipedia.org/wiki/Planet
#
# Cosmos entity residing in a solar system orbiting a star.
class Planet
  include Cosmos::SystemEntity

  CHILD_TYPES = ['Moon']

  # Alias children to moons
  alias :moons :children

  # Cosmos::Planet intializer
  def initialize(args = {})
    init_entity(args)
    init_system_entity(args)
  end

  # Return boolean indicating if this planet is valid.
  #
  # Currently tests
  # * base entity and system entity is valid
  def valid?
    entity_valid? && system_entity_valid?
    #@location.movement_strategy.is_a?(Motel::MovementStrategies::Elliptical)
  end

  # Override size_valid? to validate constraints if enabled
  def size_valid?
    super && (!enforce_constraints ||
              Omega::Constraints.valid?(size, 'planet', 'size'))
  end

  # Override type_valid? to validate constraints if enabled
  def type_valid?
    type.is_a?(Integer)
  end

  # Return json representation of planet
  def to_json(*a)
    { :json_class => self.class.name,
      :data       => entity_json.merge(system_entity_json)
    }.to_json(*a)
  end

  # Create new planet from json representation
  def self.json_create(o)
    p = new(o['data'])
    return p
  end
end # class Planet
end # module Entities
end # module Cosmos
