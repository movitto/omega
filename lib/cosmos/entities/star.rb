# Cosmos Star definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'

module Cosmos
module Entities

# http://en.wikipedia.org/wiki/Star
#
# Cosmos entity residing in a solar system
class Star
  include Cosmos::Entity
  include Cosmos::SystemEntity

  CHILD_TYPES = []

  VALIDATE_SIZE  = proc { |s| (400...550).include?(s) }
  VALIDATE_COLOR = proc { |c| ['FFFF00'].include?(c)  }

  RAND_SIZE      = proc { rand(150) + 400             }
  RAND_COLOR     = proc { 'FFFF00'                    }

  # Cosmos::Star intializer
  def initialize(args = {})
    init_entity(args)
    init_system_entity(args)
  end

  # Return boolean indicating if this star is valid.
  #
  # Currently tests
  # * base entity & system entity is valid
  # * location is stopped
  def valid?
    entity_valid? && system_entity_valid? &&
    @location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped)
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
