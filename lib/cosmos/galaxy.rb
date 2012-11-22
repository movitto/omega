# Cosmos Galaxy definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# http://en.wikipedia.org/wiki/Galaxy
#
# Cosmos entity residing in the Universe, added directly to the
# {Cosmos::Registry}. May contain local solar_system children or
# reference a remote server which children should be retrieved from.
#
# These are the top level objects in the entity heirarchies and their
# corresponding location heirarchies. In the Cosmos subsystem, the
# universe corresponds to the Cosmos::Registry to which the galaxies
# are added. All other cosmos entities are added to / under the
# galaxies themselves.
class Galaxy

  # Unique name of the galaxy
  attr_accessor :name
  alias :id :name

  # {Motel::Location} in universe which galaxy resides in the universe
  attr_accessor :location

  # Array of child {Cosmos::SolarSystem} tracked locally
  attr_reader :solar_systems

  # @group Physical Characteristics

  MAX_BACKGROUNDS = 7

  # Background to render galaxy w/ (TODO this shouldn't be here / should be up to client)
  attr_reader :background

  # @endgroup

  # Remote queue which to retrieve child solar_systems from if any (may be nil)
  attr_accessor :remote_queue

  # Cosmos::Galaxy intializer
  # @param [Hash] args hash of options to initialize galaxy with
  # @option args [String] :name,'name' unqiue name to assign to the galaxy
  # @option args [Motel::Location] :location,'location' location of the galaxy,
  #   if not specified will automatically be created with coordinates (0,0,0)
  # @option args [Array<Cosmos::SolarSystem>] :solar_systems,'solar_systems' array of solar systems to assign to galaxy
  # @option args [String] :remote_queue,'remote_queue' remote_queue to assign to galaxy if any
  def initialize(args = {})
    @name          = args['name']          || args[:name]
    @location      = args['location']      || args[:location]
    @solar_systems = args['solar_systems'] || args[:solar_systems] || []
    @remote_queue  = args['remote_queue']  || args[:remote_queue] || nil

    @background = "galaxy#{rand(MAX_BACKGROUNDS-1)+1}"


    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  # Return boolean indicating if this galaxy is valid.
  #
  # Tests the various attributes of the Galaxy, returning 'true'
  # if everything is consistent, else false.
  #
  # Currently tests
  # * name is set to a valid (non-empty) string
  # * location is set to a valid Motel::Location and is not moving
  # * solar_system is an array of valid Cosmos::SolarSystem instances
  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    @solar_systems.is_a?(Array) && @solar_systems.find { |s| !s.is_a?(Cosmos::SolarSystem) || !s.valid? }.nil?
  end

  # Return boolean indicating if this galaxy can accept the specified resource
  # @return false
  def accepts_resource?(res)
    false
  end

  # Returns the {Cosmos::Registry} lookup key corresponding to the entity's parent
  # @return [:universe]
  def self.parent_type
    :universe
  end

  # Returns boolean indicating if remote cosmos retrieval can be performed for entity's children
  # @return [true]
  def self.remotely_trackable?
    true
  end

  # Return parent of the Galaxy
  # @return [nil]
  def parent
    nil
  end

  # Set parent of the Galaxy, currently does nothing
  def parent=(val)
    # intentionally left empty as no need to add registry here
  end

  # Return children systems
  # @return [Array<Cosmos::SolarSystem>]
  def children
    @solar_systems
  end

  # Add solar_system to galaxy.
  #
  # First peforms basic checks to ensure solar system is valid in the
  # context of the galaxy, after which it is added to the local solar_systems array
  #
  # @param [Cosmos::SolarSystem] solar_system system to add to galaxy
  # @raise ArgumentError if solar_system is not valid in the context of the local galaxy
  # @return [Cosmos::SolarSystem] the system just added
  def add_child(solar_system)
    raise ArgumentError, "child must be a solar system" if !solar_system.is_a?(Cosmos::SolarSystem)
    raise ArgumentError, "solar system name #{solar_system.name} is already taken" if @solar_systems.find { |s| s.name == solar_system.name }
    raise ArgumentError, "solar system #{solar_system} already added to galaxy" if @solar_systems.include?(solar_system)
    raise ArgumentError, "solar system #{solar_system} must be valid" unless solar_system.valid?
    solar_system.location.parent_id = location.id
    solar_system.parent = self
    @solar_systems << solar_system
    solar_system
  end

  # Remove child solar_system from galaxy.
  #
  # Ignores / just returns if system is not found
  #
  # @param [Cosmos::SolarSystem,String] child solar_system to remove from galaxy or its name
  def remove_child(child)
    @solar_systems.reject! { |ch| (child.is_a?(Cosmos::SolarSystem) && ch == child) ||
                                  (child == ch.name) }
  end

  # Returns boolean indicating if the galaxy has one or more child solar_systems
  def has_children?
    return @solar_systems.size > 0
  end

  # Iterates over each child solar_system invoking block w/ the system as a parameter
  #   and then invoking 'each_child' on the system
  #
  # @param [Callable] bl callable block parameter to invoke w/ each child system and their children
  def each_child(&bl)
    @solar_systems.each { |sys|
      bl.call self, sys
      sys.each_child &bl
    }
  end

   # Convert galaxy to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => @name,
          :background => @background,
          :remote_queue => @remote_queue,
          :location => @location, :solar_systems => @solar_systems}
     }.to_json(*a)
   end

  # Convert galaxy to human readable string and return it
   def to_s
     "galaxy-#{@name}"
   end

   # Create new galaxy from json representation
   def self.json_create(o)
     galaxy = new(o['data'])
     return galaxy
   end
end
end
