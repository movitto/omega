# Manufactured Loot definition
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/registry'
require 'cosmos/entities/solar_system'

require 'omega/constraints'
require 'manufactured/entity_mixins'

module Manufactured

# Free floating groups of items (resources/etc) in a {Cosmos::Entities::SolarSystem}
# which {Manufactured::Ship}s can retrieve if within collection_distance
class Loot
  include Omega::ConstrainedAttributes
  include Manufactured::Entity::InSystem
  include Manufactured::Entity::HasCargo

  # Unique string id of the loot
  attr_accessor :id

  # Loot initializer
  def initialize(args = {})
    attr_from_args args, :id => nil
    location_from_args       args
    system_from_args         args
    cargo_from_args          args
  end

  # Return boolean indicating if this loot is valid
  def valid?
    id_valid? && location_valid? && system_valid?
  end

  # Return bool indicating if loot location is valid
  def location_valid?
    super &&
    location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped)
  end

  # Return boolean indicating if id is valid
  def id_valid?
    !@id.nil? && @id.is_a?(String) && @id != ""
  end

  # Just for compatability for now, always return true
  def alive?
    true
  end

  # Convert loot to json representation and return it
  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       => {:id => id}.merge(system_json).merge(cargo_json)
    }.to_json(*a)
  end

  # Convert loot to human readable string and return it
  def to_s
    "loot-#{@id}"
  end

  # Create new loot from json representation
  def self.json_create(o)
    loot = new(o['data'])
    return loot
  end
end

end
