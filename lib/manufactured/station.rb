# Manufactured Station definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entities/solar_system'

require 'manufactured/entity'
require 'manufactured/callbacks'
require 'manufactured/ship'

module Manufactured

# A player owned entity residing in a {Cosmos::Entities::SolarSystem}.
# They can move inbetween systems on their own without requiring a
# {Cosmos::JumpGate}. May construct other manufactured entities
# depending on the station type.
class Station
  include Manufactured::Entity::InSystem
  include Manufactured::Entity::HasCargo

  # Unique string id of the station
  attr_accessor :id

  # ID of user which station belongs to
  attr_accessor :user_id

  # Size of the station
  attr_accessor :size

  # [TYPE] General category / classification of station
  attr_reader :type

  # Set station type
  #
  # Assigns size to that corresponding to type
  # @param [TYPE] val type to assign to the station
  def type=(val)
    @type = val
    @type = TYPES.find { |t|
              t.to_s == @type
            } if @type.is_a?(String)
    @size = SIZES[@type]
  end

  # Array of callbacks to invoke on certain events relating to ship
  attr_accessor :callbacks

  # Max distance a ship can be from station to dock with it
  attr_accessor :docking_distance

  # TODO number of ships which may be docked to the station at any one time
  #attr_reader :ports

  # Distance away from the station which new entities are constructed
  attr_accessor :construction_distance

  # General station classification, used to determine
  # a station's capabilities
  TYPES = [:defense, :offense, :mining, :exploration, :science,
           :technology, :manufacturing, :commerce]

  # Mapping of station types to default sizes
  SIZES = {:defense => 35, :offense => 35, :mining => 27,
           :exploration => 20, :science => 20,
           :technology => 20, :manufacturing => 40,
           :commerce => 30}

  # Return the cost to construct a station of the specified type
  #
  # TODO right now just return a fixed cost for every station, eventually make more variable
  #
  # @param [TYPE] type type of station which to return construction cost
  # @return [Integer] quantity of resources required to construct station
  def self.construction_cost(type)
    100
  end

  # Return the time (in seconds) to construct a station of the specified type
  #
  # TODO right now just return a fixed time for every station, eventually make more variable
  #
  # @param [TYPE] type type of station which to return construction time
  # @return [Float] seconds which it takes to construct the station
  def self.construction_time(type)
    10
  end

  # Station initializer
  # @param [Hash] args hash of options to initialize attack command with
  # @option args [String] :id,'id' id to assign to the station
  # @option args [String] :user_id,'user_id' id of user that owns the station
  # @option args [TYPE] :type,'type' type to assign to station, if not set a random type will be assigned
  # @option args [Hash<Symbol,Array<String>] :errors,'errors' operation errors to set on station
  # @option args [Hash<String,Int>] :resources,'resources' hash of resource ids to quantities contained in the station
  # @option args [Cosmos::Entities::SolarSystem] :solar_system,'solar_system' solar system which the station is in
  # @option args [Motel::Location] :location,'location' location of the station in the solar system
  def initialize(args = {})
    args[:location] =
      Motel::Location.new :coordinates => [0,0,1],
                          :orientation => [1,0,0]  unless args.has_key?(:location) ||
                                                          args.has_key?('location')

    attr_from_args args, :id                   => nil,
                         :user_id              => nil,
                         :type                 => nil,
                         :callbacks            =>  [],
                         :resources            =>  [],
                         :location             => nil,
                         :system_id            => nil,
                         :solar_system         => nil,
                         :docking_distance     => 100,
                         :transfer_distance    => 100,
                         :construction_distance=>  50,
                         :cargo_capacity       => 10000
  end

  # Return boolean indicating if this station is valid
  #
  # Tests the various attributes of the Station, returning true
  # if everything is consistent, else false.
  #
  # Current tests
  # * id is set to a valid (non-empty) string
  # * location is set to a Motel::Location
  # * user id is set to a string
  # * type is one of valid TYPES
  # * size corresponds to the correct value for type
  # * solar system is set to Cosmos::Entities::SolarSystem
  # * resources is a list of resources
  #
  # At a minimum the following should be set on the default station
  # to be valid:
  # - id
  # - user_id
  # - solar_system
  # - type
  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&
    !@user_id.nil? && @user_id.is_a?(String) &&

    !@location.nil? && @location.is_a?(Motel::Location) &&
    !@solar_system.nil? && @solar_system.is_a?(Cosmos::Entities::SolarSystem) &&

    !@type.nil? && TYPES.include?(@type) &&
    !@size.nil? && @size == SIZES[@type] &&

    self.resources_valid?

    # TODO validate cargo properties when they become variable
  end

  # Return true / false indicating station permits specified ship to dock
  #
  # @param [Manufactured::Ship] ship ship which to give or deny docking clearance
  # @return [true,false] indicating if ship is allowed to dock at station
  def dockable?(ship)
    # TODO incorporate # of ports
    (ship.location.parent.id == @location.parent.id) &&
    (ship.location - @location) <= @docking_distance &&
    !ship.docked?
  end

  # Return true / false indiciating if station can construct entity specified by args.
  #
  # @param [Hash] args args which will be passed to {#construct} to construct entity
  # @return [true,false] indicating if station can construct entity
  def can_construct?(args = {})
    @type == :manufacturing &&

    ['Ship', 'Station'].include?(args[:type]) &&

    cargo_quantity >= Manufactured.const_get(args[:type]).construction_cost(args)
  end

  # Use this station to construct new manufactured entities.
  #
  # Sets up the entity in the correct context, including the right
  # location properties and verifies its validitiy before deducting
  # resources necessary to construct and instanting new entity.
  #
  # @param [Hash] args hash of options to pass to new entity being initialized
  # @option args [String] :entity_type,'entity_type' string class name of entity being constructed
  # @return new entity created, nil otherwise
  def construct(args = {})
    # return if we can't construct
    return nil unless can_construct?(args)

    # grab handle to entity class & generate construction cost
    eclass = Manufactured.const_get(args[:type])
    ecost  = eclass.construction_cost(args)

    # remove resources from the station
    # TODO map entities to specific construction requirements
    remaining = ecost
    @resources.each { |r|
      if r.quantity > remaining
        r.quantity -= remaining
        break
      else
        remaining -= r.quantity
        @resources.delete(r)
      end
    }

    # instantiate the new entity
    entity = eclass.new args
    entity.location.parent = self.location.parent

    # setup location
    entity.parent = self.parent

    # allow user to specify coordinates unless too far away
    # in which case, construct at closest location to specified
    # location withing construction distance
    distance = entity.location - self.location
    if distance > @construction_distance
      dx = (entity.location.x - self.location.x) / distance
      dy = (entity.location.y - self.location.y) / distance
      dz = (entity.location.z - self.location.z) / distance
      entity.location.x = self.location.x + dx * @construction_distance
      entity.location.y = self.location.y + dy * @construction_distance
      entity.location.z = self.location.z + dz * @construction_distance
    end

    entity
  end

  # Convert station to human readable string and return it
  def to_s
    "station-#{@id}"
  end

  # Convert station to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:id => id, :user_id => user_id,
          :type => type, :size => size,
          :docking_distance => @docking_distance,
          :location => @location,
          :system_id => (@solar_system.nil? ? @system_id : @solar_system.name),
          :resources => @resources}
     }.to_json(*a)
   end

  # Create new station from json representation
   def self.json_create(o)
     station = new(o['data'])
     return station
   end

end
end
