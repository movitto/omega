# Manufactured Entity Mixins
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/resource'

module Manufactured
module Entity

# Mixin indicating entity is in a system
module InSystem

  # [Motel::Location] of the ship in its parent solar system
  attr_reader :location

  # Set location and parent
  def location=(val)
    @location = val

    unless val.nil? || solar_system.nil? ||
           (@location.parent_id !=    # need check to skip
            solar_system.location.id) # this when updating loc
      @location.parent = solar_system.location
    end
  end

  alias :loc :location
  alias :loc= :location=

  # Alias movement_strategy to location.movement_strategy
  def movement_strategy
    @location.movement_strategy
  end

  # Alias movement_strategy= to location.movement_strategy=
  def movement_strategy=(val)
    @location.movement_strategy=val
  end

  # [Cosmos::SolarSystem] the ship is in
  attr_reader :solar_system

  # Set system and system id
  def solar_system=(val)
    @solar_system = val

    unless val.nil? # check loc.parent_id == val.location.id ?
      @system_id    = val.id
      @location.parent = val.location
    end
  end

  alias :parent :solar_system
  alias :parent= :solar_system=

  # [String] id of the solar system ship is in
  attr_accessor :system_id

  alias :parent_id :system_id

end

# Mixin indicating entity has cargo
#
# Assumes 'id' and 'location' properties are accessible
module HasCargo

  # List of resources contained in the entity
  attr_accessor :resources

  # @!group Cargo Properties

  # Max cargo capacity of entity
  # @see #cargo_quantity
  attr_accessor :cargo_capacity

  # @!endgroup


  # @!group Transfer properties

  # Max distance ship may be away from a target to transfer to it
  attr_accessor :transfer_distance

  # @!endgroup

  def cargo_empty?
    self.cargo_quantity == 0
  end

  def cargo_full?
    self.cargo_quantity >= @cargo_capacity
  end

  def cargo_space
    self.cargo_capacity - self.cargo_quantity
  end
  
  # Return bool indicating if resources are valid
  def resources_valid?
    @resources.is_a?(Array) &&
    @resources.select { |r|
      !r.is_a?(Cosmos::Resource)
    }.empty? # TODO verify resources are valid in context of entity
  end

  # Add resource locally
  #
  # @param [Resource] resource to add
  # @raise [RuntimeError] if entity cannot accept resource
  def add_resource(resource)
    raise RuntimeError,
          "entity cannot accept resource" unless can_accept?(resource)
    res = @resources.find { |r| r.material_id == resource.material_id }
    if res.nil?
      resource.entity = self
      @resources << resource
    else
      res.quantity += resource.quantity
    end
    nil
  end

  # Remove specified quantity of resource specified by material id from entity
  #
  # @param [Resource] resource to remove
  # @raise [RuntimeError] if resource cannot be removed
  def remove_resource(resource)
    res = @resources.find { |r|
      r.material_id == resource.material_id &&
      r.quantity >= resource.quantity
    }
    raise RuntimeError,
          "entity does not contain specified resource" if res.nil?

    if res.quantity == resource.quantity
      @resources.delete(res)
    else
      res.quantity -= resource.quantity
    end
    nil
  end

  # Determine the current cargo quantity
  #
  # @return [Integer] representing the amount of resource/etc in the entity
  def cargo_quantity
    @resources.inject(0) { |t,r| t+= r.quantity }
  end

  # Return boolean if entity can transfer specified quantity of resource
  # specified by material_id to specified destination
  #
  # @param [Manufactured::Entity] to_entity entity which resource is being transfered to
  # @param [Resource] resource being transfered
  def can_transfer?(to_entity, resource)
    res =
      @resources.find { |r|
        r.material_id == resource.material_id &&
        r.quantity >= resource.quantity
      }

    same_entity =
      id == to_entity.id 

    same_system =
      (location.parent_id == to_entity.location.parent_id)

    close_enough =
      ((location - to_entity.location) <= @transfer_distance)

    !same_entity && !res.nil? && same_system &&  close_enough
  end

  # Return boolean indicating if entity can accpt the specified quantity
  # of the resource specified by id
  #
  # @param [Resource] resource being transferred
  def can_accept?(resource, quantity=resource.quantity)
    self.cargo_quantity + quantity <= @cargo_capacity
  end


end # module HasCargo
end # module Entity
end # module Manufactured
