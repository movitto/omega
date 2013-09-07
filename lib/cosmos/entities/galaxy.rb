# Cosmos Galaxy definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'

module Cosmos
module Entities

# http://en.wikipedia.org/wiki/Galaxy
#
# Cosmos entity residing in the Universe, added directly to the
# {Cosmos::Registry}. May contain local solar_system children
class Galaxy
  include Cosmos::Entity
  include Cosmos::EnvEntity

  PARENT_TYPE = 'NilClass'
  CHILD_TYPES = ['SolarSystem']

  NUM_BACKGROUNDS = 6

  # Alias children to solar systems
  alias :solar_systems :children

  # Cosmos::Galaxy intializer
  def initialize(args = {})
    init_entity(args)
    init_env_entity(args)
  end

  # Return boolean indicating if this galaxy is valid.
  #
  # Currently tests
  # * base entity is valid
  # * location is stopped
  def valid?
    entity_valid? &&
    @location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped)
  end

  # Return json representation of galaxy
  def to_json(*a)
    { :json_class => self.class.name,
      :data       => entity_json.merge(env_entity_json)
    }.to_json(*a)
  end

   # Create new galaxy from json representation
   def self.json_create(o)
     g = new(o['data'])
     return g
   end

end # class Galaxy
end # module Entities
end # module Cosmos
