# Manufactured Ship definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos'

module Manufactured

# A player owned vehicle, residing in a {Cosmos::SolarSystem}.
# Ships requires {Cosmos::JumpGate}s to travel in between systems
# and may mine resources and attack other manufactured entities
# depending on the ship type
class Ship
  # Unique string id of the ship
  attr_accessor :id

  # ID of user which ship belongs to
  attr_accessor :user_id

  # Size of the ship
  #
  # TODO replace with a more accurate description of ship's geometry
  attr_accessor :size

  # [Motel::Location] of the ship in its parent solar system
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

  # Helper utility to store movement strategies which to set ship's
  # location to.
  #
  # Not used / enforced here, simply provides a centralized location
  # to register one or more movement strategies for future use
  def next_movement_strategy(ms = nil)
    @movement_strategies ||= []

    if ms.nil?
      return @movement_strategies.shift

    #elsif ms == []
    #  @movement_strategies = [] # TODO clear in this case?

    elsif ms.is_a?(Array)
      @movement_strategies = ms
      return nil

    else
      @movement_strategies << ms
      return nil

    end
  end

  # [SHIP_TYPE] General category / classification of ship
  attr_reader :type

  # Set ship type
  #
  # Assigns size to that corresponding to type
  # @param [SHIP_TYPE] val type to assign to the ship
  def type=(val)
    @type = val
    @size = SHIP_SIZES[val]
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

  # Array of callbacks to invoke on certain events relating to ship
  attr_accessor :notification_callbacks

  # @!group Movement Properties

  # Distance ship travels during a single movement cycle
  attr_accessor :movement_speed

  # Max angle ship can rotate in a single movmeent cycle
  attr_accessor :rotation_speed

  # @!endgroup

  # @!group Transfer properties

  # Max distance ship may be away from a target to transfer to it
  attr_reader :transfer_distance

  # @!endgroup

  # @!group Attack/Defense Properties

  # Max distance ship may be for a target to attack it
  attr_accessor :attack_distance

  # Number of attacks per second ship can launch
  attr_accessor :attack_rate

  # Damage ship deals per hit
  attr_accessor :damage_dealt

  # Hit points the ship has
  attr_accessor :hp

  # Max shield level of the ship
  attr_accessor :max_shield_level

  # Current shield level of the ship
  attr_accessor :current_shield_level

  # Shield refresh rate in units per second
  attr_accessor :shield_refresh_rate

  # Ship which destroyed this one (or its id) if applicable
  attr_accessor :destroyed_by

  # @!endgroup

  # @!group Mining Properties

  # Number of mining operations per second ship can perform
  attr_accessor :mining_rate

  # Quatity of resource being mined that can be extracted each time mining operation is performed
  attr_accessor :mining_quantity 

  # Max distance ship may be from entity to mine it
  attr_accessor :mining_distance

  # @!endgroup

  # {Manufactured::Station} ship is docked to, nil if not docked
  attr_reader :docked_at

  # {Manufactured::Ship} ship being attacked, nil if not attacking
  attr_reader :attacking

  # {Cosmos::ResourceSource} ship is mining, nil if not mining
  attr_reader :mining

  # Mapping of ids of resources contained in the ship to quantities contained
  attr_reader :resources

  # @!group Cargo Properties

  # Max cargo capacity of ship
  # @see #cargo_quantity
  attr_accessor :cargo_capacity

  # @!endgroup

  # @!group Looting Properties

  # Max distance ship may be from loot to collect it
  attr_accessor :collection_distance

  # @!endgroup

  # General ship classification, used to determine
  # a ship's capabilities
  SHIP_TYPES = [:frigate, :transport, :escort, :destroyer, :bomber, :corvette,
                :battlecruiser, :exploration, :mining]

  # Types of ships with attack capabilities
  ATTACK_SHIP_TYPES = [:escort, :destroyer, :bomber, :corvette, :battlecruiser]

  # Mapping of ship types to default sizes
  SHIP_SIZES = {:frigate => 35,  :transport => 25, :escort => 20,
                :destroyer => 30, :bomber => 25, :corvette => 25,
                :battlecruiser => 35, :exploration => 23, :mining => 25}

  # Return the cost to construct a ship of the specified type
  #
  # TODO right now just return a fixed cost for every ship, eventually make more variable
  #
  # @param [SHIP_TYPE] type type of ship which to return construction cost
  # @return [Integer] quantity of resources required to construct ship
  def self.construction_cost(type)
    100
  end

  # Return the time (in seconds) to construct a ship of the specified type
  #
  # TODO right now just return a fixed time for every ship, eventually make more variable
  #
  # @param [SHIP_TYPE] type type of ship which to return construction time
  # @return [Float] seconds which it takes to construct the ship
  def self.construction_time(type)
    5
  end

  # Return boolean indicating if the ship is currently 'doing something' eg
  # engaged in any activity
  def doing_something?
  end

  # Ship initializer
  # @param [Hash] args hash of options to initialize ship with
  # @option args [String] :id,'id' id to assign to the ship
  # @option args [String] :user_id,'user_id' id of user that owns the ship
  # @option args [SHIP_TYPE] :type,'type' type to assign to ship, if not set a random type will be assigned
  # @option args [Integer] :size,'size' size to assign to ship, if not set will be set to size corresponding to type
  # @option args [Manufactured::Station] :docked_at,'docked_at' station which ship is docket at
  # @option args [Manufactured::Ship] :attacking,'attacking' manufactured ship which the ship is attacking
  # @option args [Cosmos::ResourceSource] :mining,'mining' resource source which the ship is mining
  # @option args [Array<Manufactured::Callback>] :notifications,'notifications' array of manufactured callbacks to assign to ship
  # @option args [Hash<String,Int>] :resources,'resources' hash of resource ids to quantities contained in the ship
  # @option args [Float,Int] :hp,'hp' hit points to assign to ship
  # @option args [Float,Int] :max_shield_level,'max_shield_level' max_shield_level to assign to ship
  # @option args [Float,Int] :current_shield_level,'current_shield_level' current_shield_level to assign to ship
  # @option args [Cosmos::SolarSystem] :solar_system,'solar_system' solar system which the ship is in
  # @option args [Motel::Location] :location,'location' location of the ship in the solar system
  # @option args [Motel::MovementStrategy] :movement_strategy convenience setter of ship's location's movement strategy
  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @user_id  = args['user_id']  || args[:user_id]
    @type     = args['type']     || args[:type]
    @type     = @type.intern if !@type.nil? && @type.is_a?(String)
    @type     = SHIP_TYPES[rand(SHIP_TYPES.size)] if @type.nil?
    @size     = args['size']     || args[:size] || (@type.nil? ? nil : SHIP_SIZES[@type])
    @docked_at= args['docked_at']|| args[:docked_at]
    @attacking= args['attacking']|| args[:attacking]
    @mining   = args['mining']   || args[:mining]

    @notification_callbacks = args['notifications'] || args[:notifications] || []
    @resources = args[:resources] || args['resources'] || {}

    # TODO make default values variable
    #@level = TODO (combine type/level w/ centralized registry to generate these attrs?)
    @hp           = args[:hp] || args['hp'] || 10
    @current_shield_level = args[:current_shield_level] || args['current_shield_level'] || 0
    @max_shield_level = 0
    @shield_refresh_rate = 1
    @movement_speed = 5
    @rotation_speed = Math::PI / 8
    @cargo_capacity = args[:cargo_capacity] || args['cargo_capacity'] || 100
    @attack_distance = 100
    @attack_rate  = 0.5
    @damage_dealt = 2
    @mining_rate  = 0.10
    @mining_quantity = 20
    @mining_distance = 100
    @transfer_distance = 100
    @collection_distance = 100

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
    @location.orientation_x = 1 if @location.orientation_x.nil?
    @location.orientation_y = 0 if @location.orientation_y.nil?
    @location.orientation_z = 0 if @location.orientation_z.nil?

    @location.movement_strategy = args[:movement_strategy] if args.has_key?(:movement_strategy)
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
  # * type is one of valid SHIP_TYPES
  # * size corresponds to the correct value for type
  # * docked_at is set to a Manufactured::Station which permits docking
  # * attacking is set to Manufactured::Ship that can be attacked
  # * mining is set to Cosmos::ResourceSource that can be mined
  # * solar system is set to Cosmos::SolarSystem
  # * notification_callbacks is an array of Manufactured::Callbacks
  # * resources is a hash of resource ids to quantities
  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) &&
    !@user_id.nil? && @user_id.is_a?(String) && # ensure user id corresponds to actual user ?
    !@type.nil? && SHIP_TYPES.include?(@type) &&
    !@size.nil? && @size == SHIP_SIZES[@type] &&
     @current_shield_level <= @max_shield_level &&
    (@docked_at.nil? || (@docked_at.is_a?(Manufactured::Station) && can_dock_at?(@docked_at))) &&
    (@attacking.nil? || (@attacking.is_a?(Manufactured::Ship) && can_attack?(@attacking))) &&
    (@mining.nil? || (@mining.is_a?(Cosmos::ResourceSource) && can_mine?(@mining))) &&
    !@solar_system.nil? && @solar_system.is_a?(Cosmos::SolarSystem) &&
    @notification_callbacks.is_a?(Array) && @notification_callbacks.select { |nc| !nc.kind_of?(Manufactured::Callback) }.empty? && # TODO ensure validity of callbacks
    @resources.is_a?(Hash) && @resources.select { |id,q| !id.is_a?(String) || !(q.is_a?(Integer) || q.is_a?(Float)) }.empty? # TODO verify resources are valid in context of ship
    # TODO validate cargo, mining, attack properties when they become variable
  end

  # Return ship's parent solar system
  #
  # @return [Cosmos::SolarSystem]
  def parent
    return self.solar_system
  end

  # Set ship's parent solar system
  # @param [Cosmos::SolarSystem] system solar system to assign to ship
  def parent=(system)
    self.solar_system = system
  end

  # Return true / false indicating if ship can dock at station
  # @param [Manufactured::Station] station station which to check if ship can dock at
  # @return [true,false] indicating if ship is in same system and within docking distance of station
  def can_dock_at?(station)
    (@location.parent.id == station.location.parent.id) &&
    (@location - station.location) <= station.docking_distance
    # TODO ensure not already docked
  end

  # Return true / false indicating if ship can attack entity
  #
  # @param [Manufactured::Entity] entity entity to check if ship can attack
  # @return [true,false] indicating if ship can attack entity
  def can_attack?(entity)
    # TODO incoporate alliances ?
    ATTACK_SHIP_TYPES.include?(@type) && !self.docked? &&
    (@location.parent.id == entity.location.parent.id) &&
    (@location - entity.location) <= @attack_distance  &&
    @user_id != entity.user_id && self.hp > 0 && entity.hp > 0
  end

  # Return true / false indicating if ship can mine entity
  #
  # @param [Cosmos::ResourceSource] resource_source entity to check if ship can mine
  # @return [true,false] indicating if ship can mine resource source
  def can_mine?(resource_source)
    # TODO eventually filter per specific resource mining capabilities
    @type == :mining && !self.docked? &&
    (@location.parent.id == resource_source.entity.location.parent.id) &&
    (@location - resource_source.entity.location) <= @mining_distance &&
    (cargo_quantity + @mining_quantity) <= @cargo_capacity &&
    resource_source.quantity > 0
  end

  def cargo_empty?
    cargo_quantity == 0
  end

  def cargo_full?
    cargo_quantity + @mining_quantity >= @cargo_capacity
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
  # @param [Manufactured::Ship] ship which is being attacked
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
  # @param [Cosmos::ResourceSource] resource_source resource_source ship is mining
  def start_mining(resource_source)
    @mining = resource_source
  end

  # Clear ship's mining target
  def stop_mining
    @mining = nil
  end

  # Add specified quantity of resource specified by id to ship
  #
  # @param [String] resource_id id of resource being added
  # @param [Integer] quantity amount of resource to add
  # @raise [Omega::OperationError] if ship cannot accept specified quantity of resource
  def add_resource(resource_id, quantity)
    raise Omega::OperationError, "ship cannot accept resource" unless can_accept?(resource_id, quantity) # should we define an exception heirarchy local to manufactured so as not to pull in omega here?
    @resources[resource_id] ||= 0
    @resources[resource_id] += quantity
  end

  # Remove specified quantity of resource specified by id from ship
  #
  # @param [String] resource_id id of resource being removed
  # @param [Integer] quantity amount of resource to remove
  # @raise [Omega::OperationError] if ship does not have the specified quantity of resource
  def remove_resource(resource_id, quantity)
    unless @resources.has_key?(resource_id) && @resources[resource_id] >= quantity
      raise Omega::OperationError, "ship does not contain specified quantity of resource" 
    end
    @resources[resource_id] -= quantity
    @resources.delete(resource_id) if @resources[resource_id] <= 0
  end

  # Determine the current cargo quantity
  #
  # @return [Integer] representing the amount of resource/etc in the ship
  def cargo_quantity
    q = 0
    @resources.each { |id, quantity|
      q += quantity
    }
    q
  end

  # Return boolean if ship can transfer specified quantity of resource
  # specified by id to specified destination
  #
  # @param [Manufactured::Entity] to_entity entity which resource is being transfered to
  # @param [String] resource_id id of resource being transfered
  # @param [Integer] quantity amount of resource being transfered
  def can_transfer?(to_entity, resource_id, quantity)
    @id != to_entity.id &&
    @resources.has_key?(resource_id) &&
    @resources[resource_id] >= quantity &&
    (@location.parent.id == to_entity.location.parent.id) &&
    ((@location - to_entity.location) <= @transfer_distance)
  end

  # Return boolean indicating if ship can accpt the specified quantity
  # of the resource specified by id
  #
  # @param [String] resource_id id of resource being transfered
  # @param [Integer] quantity amount of resource being transfered
  def can_accept?(resource_id, quantity)
    self.cargo_quantity + quantity <= @cargo_capacity
  end

  # Convert ship to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :user_id => user_id,
         :type => type, :size => size,
         :hp => @hp, :current_shield_level => @current_shield_level,
         :cargo_capacity => @cargo_capacity,
         :attack_distance => @attack_distance,
         :mining_distance => @mining_distance,
         :docked_at => @docked_at,
         :attacking => @attacking, # TODO pass attacking via reference ?
         :mining    => @mining, # TODO pass mining via reference ?
         :location => @location,
         :system_name => (@solar_system.nil? ? @system_name : @solar_system.name),
         :resources => @resources,
         :notifications => @notification_callbacks}
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
