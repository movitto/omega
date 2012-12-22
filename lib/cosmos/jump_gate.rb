# Cosmos JumpGate definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# Represents a link between two systems.
#
# Reside in a {Cosmos::SolarSystem} (the jump_gate's parent) at a
# specified location and references another system (the endpoint). 
# Primarily interacted with by {Manufactured::Ship} instances who
# require jump gates to travel inbetween systems
class JumpGate
  # {Cosmos::SolarSystem} parent of the asteroid
  attr_accessor :solar_system

  # {Cosmos::SolarSystem} system which jump gates connects to
  attr_accessor :endpoint

  # {Motel::Location} at which jump gate resides in its parent system
  attr_accessor :location

  # Max distance in any direction around
  #   gate which entities can trigger it
  attr_reader   :trigger_distance

  # Cosmos::JumpGate intializer
  # @param [Hash] args hash of options to initialize jump gate with
  # @option args [Cosmos::SolarSystem,String] :solar_system,'solar_system'
  #   solar_system which jump gate resides in or its name to be looked up
  #   in the {Cosmos::Registry}
  # @option args [Cosmos::SolarSystem,String] :endpoint,'endpoint'
  #   solar_system which jump gate connects to or its name to be looked up
  #   in the {Cosmos::Registry}
  # @option args [Motel::Location] :location,'location' location of the asteroid,
  #   if not specified will automatically be created with coordinates (0,0,0)
  def initialize(args = {})
    @solar_system = args['solar_system'] || args[:solar_system]
    @endpoint     = args['endpoint']     || args[:endpoint]
    @location     = args['location']     || args[:location]

    # TODO make variable
    @trigger_distance = 100

    # TODO would rather not access the cosmos registry directly here
    if @solar_system.is_a?(String)
      tsolar_system = Cosmos::Registry.instance.find_entity(:type => :solarsystem,
                                                            :name => @solar_system)
      @solar_system = tsolar_system unless tsolar_system.nil?
    end

    if @endpoint.is_a?(String)
      # XXX don't like doing this here
      tendpoint = Cosmos::Registry.instance.find_entity(:type => :solarsystem,
                                                        :name => @endpoint)
      @endpoint = tendpoint unless tendpoint.nil?
    end

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  # Return boolean indicating if this jump gate is valid.
  #
  # Tests the various attributes of the JumpGate, returning 'true'
  # if everything is consistent, else false.
  #
  # Currently tests
  # * location is set to a valid Motel::Location and is not moving
  # * solar_system is set to a Cosmos::SolarSystem
  # * endpoint is set to a Cosmos::SolarSystem
  def valid?
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::SolarSystem) || @solar_system.is_a?(String)) && # XXX don't like this string hack (needed for restore state)
    (@endpoint.nil? || @endpoint.is_a?(Cosmos::SolarSystem) || @endpoint.is_a?(String))
    # && @solar_system.name != @endpoint.name
  end

  # Return boolean indicating if this jump gate can accept the specified resource
  # @return false
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

  # Return solar_system parent of the JumpGate
  # @return [Cosmos::SolarSystem]
  def parent
    @solar_system
  end

  # Set solar_system parent of the asteroid
  # @param [Cosmos::SolarSystem] solar_system
  def parent=(solar_system)
    @solar_system = solar_system
  end

  # Returns boolean indicating if jump_gate has children (always false)
  def has_children?
    false
  end

   # Convert jump_gate to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:trigger_distance => @trigger_distance,
         :solar_system     => (@solar_system.is_a?(String) ?
                               @solar_system : @solar_system.name),
         :endpoint         => (@endpoint.is_a?(String)     ?
                               @endpoint : @endpoint.name),
         :location         => @location}
    }.to_json(*a)
  end

  # Convert jump gate to human readable string and return it
  def to_s
    "jump_gate-#{solar_system}-#{endpoint}"
  end

   # Create new jump gate from json representation
  def self.json_create(o)
    jump_gate = new(o['data'])
    return jump_gate
  end

end
end
