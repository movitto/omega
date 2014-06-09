# Manufactured Station definition
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/constraints'
require 'manufactured/entity_mixins'

module Manufactured

# A player owned entity residing in a {Cosmos::Entities::SolarSystem}.
# They can move inbetween systems on their own without requiring a
# {Cosmos::Entities::JumpGate}. May construct other manufactured entities
# depending on the station type.
class Station
  include Omega::ConstrainedAttributes
  include Manufactured::Entity::Base
  include Manufactured::Entity::InSystem
  include Manufactured::Entity::HasCargo
  include Manufactured::Entity::HasCallbacks
  include Manufactured::Entity::HasDocks
  include Manufactured::Entity::ConstructionCapabilities
  extend Manufactured::Entity::Constructable

  # Station initializer
  # @param [Hash] args hash of options to initialize station with, accepts
  #   key/value pairs corresponding to all mutable station attribute
  def initialize(args = {})
    base_attrs_from_args args
    callbacks_from_args  args
    location_from_args   args
    system_from_args     args
    cargo_from_args      args
  end

  # Return all updatable attributes
  def updatable_attrs
    updatable_system_attrs + updatable_cargo_attrs
  end

  # Update this station's attributes from other station
  #
  # @param [Manufactured::Station] station entity from which to copy values from
  def update(station)
    update_from(station, *updatable_attrs)
  end

  # Return boolean indicating if this station is valid
  #
  # At a minimum the following should be set on the default station
  # to be valid:
  # - id
  # - user_id
  # - system_id
  # - type
  def valid?
    base_attrs_valid? && location_valid? && system_valid? && resources_valid?
  end

  # Just for compatability for now, always return true
  def alive?
    true
  end

  # Convert station to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => base_json.merge(system_json).
                                merge(cargo_json).
                                merge(docks_json)
    }.to_json(*a)
  end

  # Convert station to human readable string and return it
  def to_s
    "station-#{id}"
  end

  # Create new station from json representation
   def self.json_create(o)
     station = new(o['data'])
     return station
   end
end # class Station
end # module Manufactured
