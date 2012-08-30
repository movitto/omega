# Cosmos Star definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# http://en.wikipedia.org/wiki/Star
#
# Cosmos entity residing in a solar system
class Star

  # Unique name of the star
  attr_accessor :name

  # {Motel::Location} at which star resides in its parent system
  attr_accessor :location

  # @!group Physical Characteristics

  # Color of the star
  attr_reader   :color

  # Size of the star
  attr_reader   :size

  # @!endgroup

  # {Cosmos::SolarSystem} parent of the star
  attr_reader :solar_system

  # Array of valid values for star's color
  STAR_COLORS = ["FFFF00"]

  # @!group  Size Boundaries
  MAX_STAR_SIZE = 55
  MIN_STAR_SIZE = 40
  # @!endgroup

  # Cosmos::Star intializer
  #
  # @param [Hash] args hash of options to initialize star with
  # @option args [String] :name,'name' unqiue name to assign to the star
  # @option args [Motel::Location] :location,'location' location of the star,
  #   if not specified will automatically be created with coordinates (0,0,0)
  # @option args [String] :color,'color' 6 digit HEX color of star (should be on of {STAR_COLORS})
  # @option args [Integer] :size,'size' size of the star (should be withing boundaries)
  def initialize(args = {})
    @name = args['name'] || args[:name]
    @location = args['location'] || args[:location]
    @solar_system = args['solar_system'] || args[:solar_system]
    @color = args['color'] || args[:color] || STAR_COLORS[rand(STAR_COLORS.length)]
    @size  = args['size']  || args[:size]  || (rand(MAX_STAR_SIZE - MIN_STAR_SIZE) + MIN_STAR_SIZE)

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  # Return boolean indicating if this star is valid.
  #
  # Tests the various attributes of the Star, returning 'true'
  # if everything is consistent, else false.
  #
  # Currently tests
  # * name is set to a valid (non-empty) string
  # * location is set to a valid Motel::Location and is not moving
  # * solar_system is set to a Cosmos::SolarSystem
  # * size in an integer in the valid range
  # * color is a string and one of valid values
  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::SolarSystem)) &&
    (@size.is_a?(Integer) || @size.is_a?(Float)) && @size <= MAX_STAR_SIZE && @size >= MIN_STAR_SIZE &&
    @color.is_a?(String) && STAR_COLORS.include?(@color)
  end

  # Return boolean indicating if this star can accept the specified resource
  # @return false
  # TODO change?
  def accepts_resource?(res)
    false
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

  # Return solar_system parent of the Star
  # @return [Cosmos::SolarSystem]
  def parent
    @solar_system
  end

  # Set solar_system parent of the Planet
  # @param [Cosmos::SolarSystem] solar_system
  def parent=(solar_system)
    @solar_system = solar_system
  end

  # Returns boolean indicating if the star has children
  # @return [false]
  def has_children?
    false
  end

  # Convert star to human readable string and return it
  def to_s
    "star-#{@name}"
  end

   # Convert star to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :color => @color, :size => @size, :location => @location}
     }.to_json(*a)
   end

   # Create new star from json representation
   def self.json_create(o)
     star = new(o['data'])
     return star
   end
end
end
