# Manufactured Loot definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured

# Free floating groups of items (resources/etc) in a {Cosmos::SolarSystem}
# which {Manufactured::Ship}s can retrieve if within collection_distance
class Loot
  # Unique string id of the loot
  attr_accessor :id

  # [Motel::Location] of the loot in its parent solar system
  attr_reader :location

  # Set location of ship in its parent solar system
  #
  # Will set the parent of the specified location to correspond to the solar system's location object
  # @param [Motel::Location] val location to assign to the ship
  def location=(val)
    old_location = @location
    @location = val
    unless parent.nil? || @location.nil?
      @location.parent = parent.location

      @location.parent.remove_child(old_location)
      @location.parent.add_child(@location)
    end
  end

  # [Cosmos::SolarSystem] the ship is in
  attr_reader :solar_system

  # [String] name of the solar system.
  #
  # Used to reference the solar_system w/out having to pass
  # the entire system around
  attr_accessor :system_name

  # Set solar system the ship is in
  #
  # Assigns the parent of the ship's location to the location corresponding to the new solar system
  # @param [Cosmos::SolarSystem] val solar system parent to assign to the ship
  def solar_system=(val)
    @solar_system = val
    return if @solar_system.nil?
    @system_name  = @solar_system.name
    @location.parent = parent.location unless parent.nil? || @location.nil?
  end

  # Resources Loot Contains
  attr_reader :resources

  # Add resource to loot
  def add_resource(resource_id, quantity)
    @resources[resource_id] ||= 0
    @resources[resource_id]  += quantity
  end

  # Remove specified quantity of resource specified by id from loot
  #
  # @param [String] resource_id id of resource being removed
  # @param [Integer] quantity amount of resource to remove
  # @raise [Omega::OperationError] if loot does not have the specified quantity of resource
  def remove_resource(resource_id, quantity)
    unless @resources.has_key?(resource_id) && @resources[resource_id] >= quantity
      raise Omega::OperationError, "loot does not contain specified quantity of resource" 
    end
    @resources[resource_id] -= quantity
    @resources.delete(resource_id) if @resources[resource_id] <= 0
  end

  # Return total quantity of resources stored locally
  #
  # @return [Integer] quantity total quantity currently stored in loot
  def quantity
    tq = 0
    @resources.each { |r,q| tq += q }
    tq
  end

  # Return boolean indicating if loot is empty
  def empty?
    @resources.empty?
  end

  # Loot initializer
  # @param [Hash] args hash of options to initialize loot with
  # @option args [String] :id,'id' id to assign to the loot
  # @option args [Motel::Location] :location,'location' location of the loot in the solar system
  def initialize(args = {})
    @id        = args['id']       || args[:id]
    @resources = args['resources']|| args[:resources] || {}

    if args.has_key?('solar_system') || args.has_key?(:solar_system)
      self.solar_system = args['solar_system'] || args[:solar_system]
    elsif args.has_key?('system_name') || args.has_key?(:system_name)
      @system_name = args['system_name'] || args[:system_name]
      # TODO would rather not access the cosmos registry directly here
      solar_system= Cosmos::Registry.instance.find_entity(:type => :solarsystem,
                                                          :name => @system_name)
      self.solar_system = solar_system unless solar_system.nil?
    end

    # location should be set after solar system so parent is set correctly
    self.location = args['location'] || args[:location]

    self.location = Motel::Location.new if @location.nil?
    @location.x = 0 if @location.x.nil?
    @location.y = 0 if @location.y.nil?
    @location.z = 0 if @location.z.nil?

    self.location.movement_strategy = Motel::MovementStrategies::Stopped.instance
  end

  # Return boolean indicating if this loot is valid
  #
  # Tests the various attributes of the Loot, returning true
  # if everything is consistent, else false.
  #
  # Current tests
  # * id is set to a valid (non-empty) string
  # * location is set to a Motel::Location
  # * location movement strategy is stopped
  # * solar system is set to Cosmos::SolarSystem
  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) &&
     @location.movement_strategy == Motel::MovementStrategies::Stopped.instance &&
    !@solar_system.nil? && @solar_system.is_a?(Cosmos::SolarSystem)
  end

  # Return loots's parent solar system
  #
  # @return [Cosmos::SolarSystem]
  def parent
    return self.solar_system
  end

  # Set loots's parent solar system
  # @param [Cosmos::SolarSystem] system solar system to assign to loots
  def parent=(system)
    self.solar_system = system
  end

  # Convert loot to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id,
         :location => @location,
         :system_name => (@solar_system.nil? ? @system_name : @solar_system.name),
         :resources => @resources }
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
