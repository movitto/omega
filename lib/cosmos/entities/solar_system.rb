# Cosmos SolarSystem definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'

module Cosmos
module Entities

# http://en.wikipedia.org/wiki/Planetary_system
#
# Cosmos entity residing in a galaxy containing stars,
# planets, asteroid, and jump gates.
class SolarSystem
  include Cosmos::Entity

  PARENT_TYPE = 'Galaxy'
  CHILD_TYPES = ['Star', 'Planet', 'JumpGate', 'Asteroid']

  # {Cosmos::Galaxy} parent of the solar system
  alias :galaxy :parent
  alias :galaxy= :parent=

  # Array of child {Cosmos::Star}s
  def stars      ; children.select { |c| c.is_a?(Star) }     end

  # First child {Cosmos::Star}
  def star       ; stars.first                               end

  # Array of child {Cosmos::Planet}s
  def planets    ; children.select { |c| c.is_a?(Planet) }   end

  # Array of child {Cosmos::JumpGate}
  def jump_gates ; children.select { |c| c.is_a?(JumpGate) } end

  # Array of child {Cosmos::Asteroid}
  def asteroids  ; children.select { |c| c.is_a?(Asteroid) } end

  # Cosmos::SolarSystem intializer
  def initialize(args = {})
    init_entity(args)

    attr_from_args args, :galaxy => @parent
  end

  # Return boolean indicating if this solar system is valid.
  #
  # Currently tests
  # * base entity is valid
  # * location is stopped
  def valid?
    entity_valid? &&
    @location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped)
  end

  # Return json representation of solar system
  def to_json(*a)
    { :json_class => self.class.name,
      :data       => entity_json
    }.to_json(*a)
  end

   # Create new solar system from json representation
   def self.json_create(o)
     s = new(o['data'])
     return s
   end

end # class SolarSystem
end # module Entities
end # module Cosmos
