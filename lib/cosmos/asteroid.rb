# Cosmos Asteroid definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# http://en.wikipedia.org/wiki/Asteroid
#
# Cosmos entity residing in a solar system, may be associated with
# resources through {Cosmos::ResourceSource}. Primarily interacted with
# by {Manufactured::Ship} to mine the contained resources.
class Asteroid
  # @!group  Size Boundaries
  MAX_ASTEROID_SIZE = 20
  MIN_ASTEROID_SIZE = 10
  # @!endgroup

  # Unique name of the asteroid
  attr_accessor :name
  alias :id :name

  # @!group Physical Characteristics

  # Size of the asteroid
  attr_accessor   :size

  # Color of the asteroid
  attr_accessor   :color

  # @!endgroup

  # {Motel::Location} at which asteroid resides in its parent system
  attr_accessor :location

  # {Cosmos::SolarSystem} parent of the asteroid
  attr_accessor :solar_system

  # Cosmos::Asteroid intializer
  # @param [Hash] args hash of options to initialize asteroid with
  # @option args [String] :name,'name' unqiue name to assign to the asteroid
  # @option args [Motel::Location] :location,'location' location of the asteroid,
  #   if not specified will automatically be created with coordinates (0,0,0)
  # @option args [String] :color,'color' 6 digit HEX color of asteroid
  # @option args [Integer] :size,'size' size of the asteroid
  # @option args [Cosmos::SolarSystem] :solar_system,'solar_system' solar_system which asteroid resides in
  def initialize(args = {})
    @name     = args['name']     || args[:name]
    @location = args['location'] || args[:location]
    @color    = args['color']    || args[:color]    || ("%06x" % (rand * 0xffffff))
    @size     = args['size']     || args[:size]     || (rand(MAX_ASTEROID_SIZE-MIN_ASTEROID_SIZE) + MIN_ASTEROID_SIZE)

    @solar_system = args['solar_system'] || args[:solar_system]

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  # Return boolean indicating if this asteroid is valid.
  #
  # Tests the various attributes of the Asteroid, returning true
  # if everything is consistent, else false.
  #
  # Currently tests
  # * name is set to a valid (non-empty) string
  # * location is set to a valid Motel::Location and is not moving
  # * solar_system is set to a Cosmos::SolarSystem
  # * size in an integer in the valid range
  # * color is a string matching the valid format
  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::SolarSystem)) &&
    (@size.is_a?(Integer) || @size.is_a?(Float)) && @size <= MAX_ASTEROID_SIZE && @size >= MIN_ASTEROID_SIZE &&
    @color.is_a?(String) && !/^[a-fA-F0-9]{6}$/.match(@color).nil?
  end

  # Return boolean indicating if this asteroid can accept the specified resource.
  #
  # TODO right now indiscremenantly accepts all valid resources, make this more selective
  def accepts_resource?(res)
    res.valid?
  end

  # Returns the {Cosmos::Registry} lookup key corresponding to the entity's parent
  # @return [:solarsystem]
  def self.parent_type
    :solarsystem
  end

  # Return solar_system parent of the Asteroid
  # @return [Cosmos::SolarSystem]
  def parent
    @solar_system
  end

  # Set solar_system parent of the asteroid
  # @param [Cosmos::SolarSystem] solar_system
  def parent=(solar_system)
    @solar_system = solar_system
  end

  # Returns boolean indicating if asteroid has children (always false)
  def has_children?
    false
  end

  # Convert asteroid to human readable string and return it
  def to_s
    "asteroid-#{@name}"
  end

   # Convert asteroid to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :color => color, :size => size, :location => @location}
     }.to_json(*a)
   end

   # Create new asteroid from json representation
   def self.json_create(o)
     asteroid = new(o['data'])
     return asteroid
   end

end
end
