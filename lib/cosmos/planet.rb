# Cosmos Planet definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# http://en.wikipedia.org/wiki/Planet
#
# Cosmos entity residing in a solar system orbiting a star.
class Planet
  # @!group  Size Boundaries
  MAX_PLANET_SIZE = 20
  MIN_PLANET_SIZE = 10
  # @!endgroup

  # Unique name of the planet
  attr_accessor :name
  alias :id :name

  # @!group Physical Characteristics

  # Size of the planet
  attr_reader :size

  # Color of the planet
  attr_reader :color

  # @!endgroup

  # {Motel::Location} at which planet resides in its parent system
  attr_accessor :location

  # {Cosmos::SolarSystem} parent of the planet
  attr_reader :solar_system

  # Array of child {Cosmos::Moon} tracked locally
  attr_reader :moons

  # Cosmos::Planet intializer
  # @param [Hash] args hash of options to initialize planet with
  # @option args [String] :name,'name' unqiue name to assign to the planet
  # @option args [Motel::Location] :location,'location' location of the planet,
  #   if not specified will automatically be created with coordinates (0,0,0)
  # @option args [String] :color,'color' 6 digit HEX color of planet
  # @option args [Integer] :size,'size' size of the planet
  # @option args [Array<Cosmos::Moon>] :moons,'moons' array of moons to assign to planet
  # @option args [Cosmos::SolarSystem] :solar_system,'solar_system' solar_system which planet resides in
  # @option args [Motel::MovementStrategy] :movement_strategy a convenience parameter allowing the movement_strategy to be specified here (will be set on location)
  def initialize(args = {})
    @name     = args['name']     || args[:name]
    @location = args['location'] || args[:location]
    @color    = args['color']    || args[:color]    || ("%06x" % (rand * 0xffffff))
    @size     = args['size']     || args[:size]     || (rand(MAX_PLANET_SIZE-MIN_PLANET_SIZE) + MIN_PLANET_SIZE)

    @moons        = args['moons'] || []
    @solar_system = args['solar_system'] || args[:solar_system]

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end

    @location.movement_strategy = args[:movement_strategy] if args.has_key?(:movement_strategy)
  end

  # Return boolean indicating if this planet is valid.
  #
  # Tests the various attributes of the Planet, returning 'true'
  # if everything is consistent, else false.
  #
  # Currently tests
  # * name is set to a valid (non-empty) string
  # * location is set to a valid Motel::Location and is not moving
  # * solar_system is set to a Cosmos::SolarSystem
  # * moons is an array of valid Cosmos::Moon instances
  # * size in an integer in the valid range
  # * color is a string matching the valid format
  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && #@location.movement_strategy.class == Motel::MovementStrategies::Elliptical &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::SolarSystem)) &&
    @moons.is_a?(Array) && @moons.find { |m| !m.is_a?(Cosmos::Moon) || !m.valid? }.nil? &&
    (@size.is_a?(Integer) || @size.is_a?(Float)) && @size <= MAX_PLANET_SIZE && @size >= MIN_PLANET_SIZE &&
    @color.is_a?(String) && !/^[a-fA-F0-9]{6}$/.match(@color).nil?
  end

  # Returns the {Cosmos::Registry} lookup key corresponding to the entity's parent
  # @return [:solarsystem]
  def self.parent_type
    :solarsystem
  end

  # Returns boolean indicating if remote cosmos retrieval can be performed for entity's children
  # @return [false]
  def self.remotely_trackable?
    false
  end

  # Return boolean indicating if this planet can accept the specified resource
  # @return false 
  # TODO change?
  def accepts_resource?(res)
    false
  end

  # Return solar_system parent of the Planet
  # @return [Cosmos::SolarSystem]
  def parent
    @solar_system
  end

  # Set solar_system parent of the Planet
  # @param [Cosmos::SolarSystem] solar_system
  def parent=(solar_system)
    @solar_system = solar_system
  end

  # Return children moons
  # @return [Array<Cosmos::Moon>]
  def children
    @moons
  end

  # Add moon to planet.
  #
  # First peforms basic checks to ensure moon is valid in the
  # context of the planet, after which it is added to the local moons array
  #
  # @param [Cosmos::Moon] moon system to add to planet
  # @raise ArgumentError if moon is not valid in the context of the local planet
  # @return [Cosmos::Moon] the system just added
  def add_child(moon)
    raise ArgumentError, "child must be a moon" if !moon.is_a?(Cosmos::Moon)
    raise ArgumentError, "moon name #{moon.name} is already taken" if @moons.find { |m| m.name == moon.name }
    raise ArgumentError, "moon #{moon} already added to planet" if @moons.include?(moon)
    raise ArgumentError, "moon #{moon} must be valid" unless moon.valid?
    moon.location.parent_id = location.id
    moon.parent = self
    @moons << moon
    moon
  end

  # Remove child moon from planet.
  #
  # Ignores / just returns if moon is not found
  #
  # @param [Cosmos::Moon,String] child moon to remove from planet or its name
  def remove_child(child)
    @moons.reject! { |ch| (child.is_a?(Cosmos::Moon) && ch == child) ||
                          (child == ch.name) }
  end

  # Returns boolean indicating if the planet has one or more child moons
  def has_children?
    @moons.size > 0
  end

  # Iterates over each child moons invoking block w/ the moon as a parameter
  def each_child(&bl)
    @moons.each { |m|
      bl.call self, m
    }
  end

  # Convenience method to set movement_strategy on planet's location
  def movement_strategy=(strategy)
    @location.movement_strategy = strategy unless @location.nil?
  end

  # Convert planet to human readable string and return it
  def to_s
    "planet-#{@name}"
  end

   # Convert planet to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :color => color, :size => size, :location => @location, :moons => @moons}
     }.to_json(*a)
   end

   # Create new planet from json representation
   def self.json_create(o)
     planet = new(o['data'])
     return planet
   end

end
end
