# Manufactured Ship definition
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/constraints'
require 'manufactured/mixins/entity'

module Manufactured

# A player owned vehicle, residing in a {Cosmos::Entities::SolarSystem}.
# Ships requires {Cosmos::Entities::JumpGate}s to travel in between systems
# and may mine resources and attack other manufactured entities
# depending on the ship type
class Ship
  include Omega::ConstrainedAttributes
  include Manufactured::Entity::Base
  include Manufactured::Entity::InSystem
  include Manufactured::Entity::HasCargo
  include Manufactured::Entity::HasCallbacks
  include Manufactured::Entity::Movable
  include Manufactured::Entity::Combatent
  include Manufactured::Entity::MiningCapabilities
  include Manufactured::Entity::Dockable
  extend Manufactured::Entity::Constructable

  # Ship initializer
  #
  # @param [Hash] args hash of options to initialize ship with, accepts
  #   key/value pairs corresponding to all mutable ship attributes
  def initialize(args = {})
    base_attrs_from_args     args
    callbacks_from_args      args
    location_from_args       args
    system_from_args         args
    cargo_from_args          args
    docking_state_from_args  args
    combat_state_from_args   args
    mining_state_from_args   args
    movement_state_from_args args
  end

  # Return all updatable attributes
  def updatable_attrs
    updatable_movement_attrs + updatable_combat_attrs +
    updatable_cargo_attrs    + updatable_system_attrs +
    updatable_mining_attrs   + updatable_docking_attrs
  end

  # Update this ship's attributes from other ship
  #
  # @param [Manufactured::Ship] ship entity which to copy attributes from
  def update(ship, *attrs)
    attrs = updatable_attrs if attrs.empty?
    update_from(ship, *attrs, :skip_nil => false)
  end

  # Return boolean indicating if this ship is valid
  #
  # At a minimum the following should be set on the default ship
  # to be valid:
  # - id
  # - user_id
  # - system_id
  # - type
  def valid?
    base_attrs_valid? && location_valid? && system_valid? &&
    callbacks_valid?  && docking_valid?  && combat_context_valid? &&
    mining_context_valid? && resources_valid?
  end

  # Convert ship to json representation and return it
  # TODO mechanism/flag which to only return mutable properties
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => base_json.merge(system_json).
                                merge(movement_json).
                                merge(cargo_json).
                                merge(docking_json).
                                merge(combat_json).
                                merge(mining_json).
                                merge(callbacks_json)
    }.to_json(*a)
  end

  # Convert ship to human readable string and return it
  def to_s
    "ship-#{id}"
  end

  # Create new ship from json representation
  def self.json_create(o)
    ship = new(o['data'])
    return ship
  end
end # class Ship
end # module Manufactured
