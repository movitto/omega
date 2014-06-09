# Cosmos Moon definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'

module Cosmos
module Entities

# http://en.wikipedia.org/wiki/Natural_satellite
#
# Cosmos entity existing in proximity to a {Cosmos::Planet}.
#
# Currently does not orbit but that will be changed in the future
class Moon
  include Cosmos::Entity

  PARENT_TYPE = 'Planet'
  CHILD_TYPES = []

  alias :planet :parent
  alias :planet= :parent=

  # Cosmos::Moon intializer
  # @param [Hash] args hash of options to initialize moon with
  def initialize(args = {})
    init_entity(args)

    attr_from_args args, :planet => @parent
  end

  # Return boolean indicating if this moon is valid.
  #
  # Currently tests
  # * base entity is valid
  # * location is not moving
  def valid?
    entity_valid? &&
    @location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped)
  end

  # Return json representation of moon
  def to_json(*a)
    { :json_class => self.class.name,
      :data       => entity_json
    }.to_json(*a)
  end

   # Create new moon from json representation
   def self.json_create(o)
     m = new(o['data'])
     return m
   end

end # class Moon
end # module Entities
end # module Cosmos
