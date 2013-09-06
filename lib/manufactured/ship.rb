# Manufactured Ship definition
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entities/solar_system'
require 'manufactured/entity'
require 'motel/location'

module Manufactured

# A player owned vehicle, residing in a {Cosmos::Entities::SolarSystem}.
# Ships requires {Cosmos::Entities::JumpGate}s to travel in between systems
# and may mine resources and attack other manufactured entities
# depending on the ship type
class Ship
  include Manufactured::Entity::InSystem
  include Manufactured::Entity::HasCargo

  # Unique string id of the ship
  attr_accessor :id

  # TODO human friendly name

  # ID of user which ship belongs to
  attr_accessor :user_id

  # Size of the ship
  attr_accessor :size

  # Total distance ship moved
  attr_accessor :distance_moved

  # [SHIP_TYPE] General category / classification of ship
  attr_reader :type

  # Set ship type
  #
  # Assigns size to that corresponding to type
  # @param [SHIP_TYPE] val type to assign to the ship
  def type=(val)
    @type = val
    @type = TYPES.find { |t|
              t.to_s == @type
            } if @type.is_a?(String)
    @size = SIZES[@type]
  end

  # Callbacks to invoke on ship events
  attr_accessor :callbacks

  # Run callbacks
  def run_callbacks(type, *args)
    @callbacks.select { |c| c.event_type == type }.
               each   { |c| c.invoke self, *args  }
  end

  # @!group Movement Properties

  # Distance ship travels during a single movement cycle
  attr_accessor :movement_speed

  # Base movement speed of a ship of the specified type.
  #
  # TODO right now just return a fixed speed for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base movement speed of the ship type
  def self.base_movement_speed(type)
    5
  end


  # Max angle ship can rotate in a single movmeent cycle
  attr_accessor :rotation_speed

  # Base rotation speed of a ship of the specified type.
  #
  # TODO right now just return a fixed speed for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base rotation speed of the ship type
  def self.base_rotation_speed(type)
    # XXX: if this is too large, rotation callback will be thrown off
    #      as entity may have rotated passed specified distance in
    #      movement interval
    Math::PI / 32
  end

  # @!endgroup

  # @!group Attack/Defense Properties

  # Max distance ship may be for a target to attack it
  attr_accessor :attack_distance

  # Base attack distance of a ship of the specified type.
  #
  # TODO right now just return a fixed distance for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base attack distance which to assign to the ship
  def self.base_attack_distance(type)
    100
  end

  # Number of attacks per second ship can launch
  attr_accessor :attack_rate

  # Base attack rate of a ship of the specified type.
  #
  # TODO right now just return a fixed rate for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base attack rate which to assign to the ship
  def self.base_attack_rate(type)
    0.5
  end

  # Damage ship deals per hit
  attr_accessor :damage_dealt

  # Base damage dealt by a ship of the specified type.
  #
  # TODO right now just return a fixed value for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base damage dealt which to assign to the ship
  def self.base_damage_dealt(type)
    2
  end

  # Hit points the ship has
  attr_accessor :hp

  # Base hp of a ship of the specified type.
  #
  # TODO right now just return a fixed hp for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base hp which to assign to the ship
  def self.base_hp(type)
    25
  end

  # Max shield level of the ship
  attr_accessor :max_shield_level

  # Base shield level of a ship of the specified type.
  #
  # TODO right now just return a fixed level for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base shield level which to assign to the ship
  def self.base_shield_level(type)
    10
  end

  # Current shield level of the ship
  attr_accessor :shield_level

  # Shield refresh rate in units per second
  attr_accessor :shield_refresh_rate

  # Base shield refresh rate of a ship of the specified type.
  #
  # TODO right now just return a fixed rate for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base shield raresh rate which to assign to the ship
  def self.base_shield_refresh_rate(type)
    1
  end


  # Ship which destroyed this one (or its id) if applicable
  attr_accessor :destroyed_by

  # @!endgroup

  # @!group Mining Properties

  # Number of mining operations per second ship can perform
  attr_accessor :mining_rate

  # Base mining rate of a ship of the specified type.
  #
  # TODO right now just return a fixed rate for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base attack rate which to assign to the ship
  def self.base_mining_rate(type)
    0.10
  end

  # Quatity of resource being mined that can be extracted each time mining operation is performed
  attr_accessor :mining_quantity 

  # Base mining quantity of a ship of the specified type.
  #
  # TODO right now just return a fixed quantity for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base mining quantity which to assign to the ship
  def self.base_mining_quantity(type)
    20
  end

  # Max distance ship may be from entity to mine it
  attr_accessor :mining_distance

  # Base mining distance of a ship of the specified type.
  #
  # TODO right now just return a fixed distance for every ship,
  # eventually make more variable.
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] base mining distance which to assign to the ship
  def self.base_mining_distance(type)
    100
  end

  # @!endgroup

  # {Manufactured::Station} ship is docked to, nil if not docked
  attr_accessor :docked_at
  def docked_at_id ; @docked_at.nil? ? nil : @docked_at.id end

  # {Manufactured::Ship} ship being attacked, nil if not attacking
  attr_accessor :attacking

  # {Cosmos::Resource} ship is mining, nil if not mining
  attr_accessor :mining

  # @!group Looting Properties

  # Max distance ship may be from loot to collect it
  attr_accessor :collection_distance

  # @!endgroup

  # General ship classification, used to determine
  # a ship's capabilities
  TYPES = [:frigate, :transport, :escort, :destroyer, :bomber, :corvette,
           :battlecruiser, :exploration, :mining]

  # Types of ships with attack capabilities
  ATTACK_TYPES = [:escort, :destroyer, :bomber, :corvette, :battlecruiser]

  # Mapping of ship types to default sizes
  SIZES = {:frigate => 35,  :transport => 25, :escort => 20,
           :destroyer => 30, :bomber => 25, :corvette => 25,
           :battlecruiser => 35, :exploration => 23, :mining => 25}

  # Cost to construct a ship of the specified type
  #
  # TODO right now just return a fixed cost for every ship, eventually make more variable
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] quantity of resources required to construct ship
  def self.construction_cost(type)
    100
  end

  # Time (in seconds) to construct a ship of the specified type
  #
  # TODO right now just return a fixed time for every ship, eventually make more variable
  #
  # @param [SHIP_TYPE] type type of ship which to return construction time
  # @return [Float] seconds which it takes to construct the ship
  def self.construction_time(type)
    5
  end

  # Ship initializer
  # @param [Hash] args hash of options to initialize ship with
  # @option args [String] :id,'id' id to assign to the ship
  # @option args [String] :user_id,'user_id' id of user that owns the ship
  # @option args [SHIP_TYPE] :type,'type' type to assign to ship, if not set a random type will be assigned
  # @option args [Manufactured::Station] :docked_at,'docked_at' station which ship is docket at
  # @option args [Manufactured::Ship] :attacking,'attacking' manufactured ship which the ship is attacking
  # @option args [Cosmos::Resource] :mining,'mining' resource source which the ship is mining
  # @option args [Array<Manufactured::Callback>] :notifications,'notifications' array of manufactured callbacks to assign to ship
  # @option args [Array<Resource>] :resources,'resources' list of resources to set on ship
  # @option args [Float,Int] :hp,'hp' hit points to assign to ship
  # @option args [Float,Int] :max_shield_level,'max_shield_level' max_shield_level to assign to ship
  # @option args [Float,Int] :shield_level,'shield_level' shield_level to assign to ship
  # @option args [Cosmos::SolarSystem] :solar_system,'solar_system' solar system which the ship is in
  # @option args [Motel::Location] :location,'location' location of the ship in the solar system
  # @option args [Motel::MovementStrategy] :movement_strategy convenience setter of ship's location's movement strategy
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
                         :docked_at            => nil,
                         :attacking            => nil,
                         :mining               => nil,
                         :location             => nil,
                         :system_id            => nil,
                         :solar_system         => nil,
                         :cargo_capacity       => 100,
                         :transfer_distance    => 100,
                         :collection_distance  => 100,
                         :shield_level         =>   0,
                         :hp                   => nil

    @location.orientation = [0,0,1] if @location.orientation == [nil, nil, nil]
    @location.movement_strategy =
      args[:movement_strategy] if args.has_key?(:movement_strategy)

    @hp                   = Ship.base_hp(@type) if @hp.nil?
    @movement_speed       = Ship.base_movement_speed(@type)
    @rotation_speed       = Ship.base_rotation_speed(@type)
    @attack_distance      = Ship.base_attack_distance(@type)
    @attack_rate          = Ship.base_attack_rate(@type)
    @damage_dealt         = Ship.base_damage_dealt(@type)
    @mining_rate          = Ship.base_mining_rate(@type)
    @mining_quantity      = Ship.base_mining_quantity(@type)
    @mining_distance      = Ship.base_mining_distance(@type)
    @max_shield_level     = Ship.base_shield_level(@type)
    @shield_refresh_rate  = Ship.base_shield_refresh_rate(@type)
  end

  # Update this ship's attributes from other ship
  #
  # @param [Manufactured::Ship] ship ship which to copy attributes from
  def update(ship)
    update_from(ship, :hp, :shield_level, :distance_moved, :resources,
                      :parent_id, :parent, :system_id, :solar_system,
                      :location, :mining, :attacking)
  end

  # Return boolean indicating if this ship is valid
  #
  # Tests the various attributes of the Ship, returning true
  # if everything is consistent, else false.
  #
  # Current tests
  # * id is set to a valid (non-empty) string
  # * location is set to a Motel::Location
  # * user id is set to a string
  # * type is one of valid TYPES
  # * size corresponds to the correct value for type
  # * docked_at is set to a Manufactured::Station which permits docking
  # * attacking is set to Manufactured::Ship that can be attacked
  # * mining is set to Cosmos::Resource that can be mined
  # * solar system is set to Cosmos::SolarSystem
  # * notification_callbacks is an array of Manufactured::Callbacks
  # * resources is a list of resources
  #
  # At a minimum the following should be set on the default ship
  # to be valid:
  # - id
  # - user_id
  # - solar_system
  # - type
  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&
    !@user_id.nil? && @user_id.is_a?(String) &&

    !@location.nil? && @location.is_a?(Motel::Location) &&
    !@system_id.nil? &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::Entities::SolarSystem)) &&

    !@type.nil? && TYPES.include?(@type) &&
    !@size.nil? && @size == SIZES[@type] &&

     @shield_level <= @max_shield_level &&

    (@docked_at.nil? ||
     (@docked_at.is_a?(Manufactured::Station) && can_dock_at?(@docked_at))) &&

    (@attacking.nil? ||
     (@attacking.is_a?(Manufactured::Ship) && can_attack?(@attacking))) &&

    (@mining.nil? ||
     (@mining.is_a?(Cosmos::Resource) && can_mine?(@mining))) &&

    @callbacks.is_a?(Array) &&
    @callbacks.select { |c|
      !c.kind_of?(Manufactured::Callback)
    }.empty? && # TODO ensure validity of callbacks

    self.resources_valid?

    # TODO validate cargo, mining, attack properties when they become variable
  end

  # Return true / false indicating if the ship's hp > 0
  def alive?
    @hp > 0
  end

  # Return true / false indicating if ship can dock at station
  # @param [Manufactured::Station] station station which to check if ship can dock at
  # @return [true,false] indicating if ship is in same system and within docking distance of station
  def can_dock_at?(station)
    (@location.parent_id == station.location.parent_id) &&
    (@location - station.location) <= station.docking_distance &&
    alive?
    # TODO ensure not already docked
  end

  # Return true / false indicating if ship can attack entity
  #
  # @param [Manufactured::Entity] entity entity to check if ship can attack
  # @return [true,false] indicating if ship can attack entity
  def can_attack?(entity)
    # TODO incoporate alliances ?
    ATTACK_TYPES.include?(@type) && !self.docked? &&
    (@location.parent_id == entity.location.parent_id) &&
    (@location - entity.location) <= @attack_distance  &&
    alive? && entity.alive?
  end

  # Return true / false indicating if ship can mine entity
  #
  # @param [Cosmos::Resource] resource to check if ship can mine
  # @return [true,false] indicating if ship can mine resource source
  def can_mine?(resource, quantity=resource.quantity)
    # TODO eventually filter per specific resource mining capabilities
     @type == :mining && !self.docked? && alive? &&
    (@location.parent_id == resource.entity.location.parent_id) &&
    (@location - resource.entity.location) <= @mining_distance &&
    (cargo_quantity + quantity) <= @cargo_capacity
  end


  # Return boolean indicating if ship is currently docked
  #
  # @return [true,false] indicating if ship is docked or not
  def docked?
    !@docked_at.nil?
  end

  # Dock ship at the specified station
  #
  # @param [Manufactured::Station] station station to dock ship at
  def dock_at(station)
    @docked_at = station
  end

  # Undock ship from docked station
  def undock
    # TODO check to see if station has given ship undocking clearance
    @docked_at = nil
  end

  # Return boolean indicating if ship is currently attacking
  #
  # @return [true,false] indicating if ship is attacking or not
  def attacking?
    !@attacking.nil?
  end

  # Set ship's attack target
  #
  # @param [Manufactured::Ship] defender ship being attacked
  def start_attacking(defender)
    @attacking = defender
  end

  # Clear ship's attacking target
  def stop_attacking
    @attacking = nil
  end


  # Return boolean indicating if ship is currently mining
  #
  # @return [true,false] indicating if ship is mining or not
  def mining?
    !@mining.nil?
  end

  # Set ship's mining target
  #
  # @param [Cosmos::Resource] resource resource ship is mining
  def start_mining(resource)
    @mining = resource
  end

  # Clear ship's mining target
  def stop_mining
    @mining = nil
  end

  # Convert ship to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :user_id => user_id,
         :type => type, :size => size,
         :hp => @hp, :shield_level => @shield_level,
         :cargo_capacity => @cargo_capacity,
         :attack_distance => @attack_distance,
         :mining_distance => @mining_distance,
         :docked_at => @docked_at,
         :attacking => @attacking, # FIXME pass attacking via reference (currently if entities are attacking each other this will be circular)
         :mining    => @mining, # TODO pass mining via reference ?
         :location => @location,
         :system_id => (@solar_system.nil? ? @system_id : @solar_system.id),
         :resources => @resources}
    }.to_json(*a)
  end

  # Convert ship to human readable string and return it
  def to_s
    "ship-#{@id}"
  end

  # Create new ship from json representation
  def self.json_create(o)
    ship = new(o['data'])
    return ship
  end

end
end
