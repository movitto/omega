# Cosmos Moon definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'

module Cosmos

# http://en.wikipedia.org/wiki/Natural_satellite
#
# Cosmos entity existing in proximity to a {Cosmos::Planet}.
#
# Currently does not orbit but that will be changed in the future
class Moon
  include Cosmos::Entity

  PARENT_TYPE = 'Planet'
  CHILD_TYPES = []

  # Cosmos::Moon intializer
  # @param [Hash] args hash of options to initialize moon with
  def initialize(args = {})
    init_entity(args)
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

end
end
