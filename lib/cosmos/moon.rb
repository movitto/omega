# Cosmos Moon definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# http://en.wikipedia.org/wiki/Natural_satellite
#
# Cosmos entity existing in proximity to a {Cosmos::Planet}.
#
# Currently does not orbit but that will be changed in the future
class Moon
  # Unique name of the planet
  attr_accessor :name

  # {Motel::Location} around planet which moon is located
  attr_accessor :location

  # {Cosmos::Planet} to which moon orbits
  attr_reader :planet

  # Cosmos::Moon intializer
  # @param [Hash] args hash of options to initialize moon with
  # @option args [String] :name,'name' unqiue name to assign to the moon
  # @option args [Motel::Location] :location,'location' location of the moon,
  #   if not specified will automatically be created with coordinates (0,0,0)
  # @option args [Cosmos::Planet] :planet,'planet' planet which moon resides around
  def initialize(args = {})
    @name = args['name'] || args[:name]
    @location = args['location'] || args[:location]
    @planet   = args['planet']   || args[:planet]

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  # Return boolean indicating if this moon is valid.
  #
  # Tests the various attributes of the Moon, returning 'true'
  # if everything is consistent, else false.
  #
  # Currently tests
  # * name is set to a valid (non-empty) string
  # * location is set to a valid Motel::Location and is not moving
  # * planet is set to a Cosmos::Planet
  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    (@planet.nil? || @planet.is_a?(Cosmos::Planet))
  end

  # Return boolean indicating if this moon can accept the specified resource.
  # @return false
  #
  # TODO change
  def accepts_resource?(res)
    false
  end

  # Return planet parent of the moon
  # @return [Cosmos::Planet]
  def parent
    @planet
  end

  # Set planet parent of the moon
  # @param [Cosmos::Planet] planet
  def parent=(planet)
    @planet = planet
  end

  # Returns the {Cosmos::Registry} lookup key corresponding to the entity's parent
  # @return [:planet]
  def self.parent_type
    :planet
  end

  # Returns boolean indicating if remote cosmos retrieval can be performed for entity's children
  # @return [false]
  def self.remotely_trackable?
    false
  end

  # Returns boolean indicating if moon has children (always false)
  def has_children?
    false
  end

   # Convert moon to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :location => @location}
     }.to_json(*a)
   end

  # Convert moon to human readable string and return it
   def to_s
     "moon-#{name}"
   end

   # Create new moon from json representation
   def self.json_create(o)
     moon = new(o['data'])
     return moon
   end

end
end
