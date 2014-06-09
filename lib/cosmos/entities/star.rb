# Cosmos Star definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'cosmos/system_entity'
require 'omega/constraints'

module Cosmos
module Entities

# http://en.wikipedia.org/wiki/Star
#
# Cosmos entity residing in a solar system
class Star
  include Cosmos::SystemEntity

  # Alias type to rgb color
  alias :color  :type
  alias :color= :type=

  CHILD_TYPES = []

  # Cosmos::Star intializer
  def initialize(args = {})
    init_entity(args)
    init_system_entity(args)
  end

  # Return boolean indicating if this star is valid.
  def valid?
    entity_valid? && system_entity_valid?
  end

  # Return bool indiciating if star location is valid
  def location_valid?
    super &&
    @location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped)
  end

  # Override size_valid? to validate constraints if enabled
  def size_valid?
    super && (!enforce_constraints ||
              Omega::Constraints.valid?(size, 'star', 'size'))
  end

  # Override type_valid? to validate type is
  def type_valid?
    type.is_a?(String) && (!enforce_constraints ||
                           Omega::Constraints.valid?(type, 'star', 'type'))
  end

  # Return json representation of star
  def to_json(*a)
    { :json_class => self.class.name,
      :data       => entity_json.merge(system_entity_json)
    }.to_json(*a)
  end

  # Create new star from json representation
  def self.json_create(o)
    s = new(o['data'])
    return s
  end
end # class Star
end # module Entities
end # module Cosmos
