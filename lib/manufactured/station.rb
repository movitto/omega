# Manufactured Station definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured

# A player owned entity residing in a {Cosmos::SolarSystem}.
# They can move inbetween systems on their own without requiring a
# {Cosmos::JumpGate}. May construct other manufactured entities
# depending on the station type.
class Station
  # Unique string id of the station
  attr_accessor :id

  # ID of user which station belongs to
  attr_accessor :user_id

  # Hit points the station has.
  # Currently not used, here for compatability reasons
  attr_accessor :hp

  # Size of the station
  #
  # TODO replace with a more accurate description of station's geometry
  attr_accessor :size

  # Error invoked during operations if any, mapping between operation
  # identifiers (symbols) and array of string errors
  attr_accessor :errors

  # Clear operation errors
  def clear_errors(args = {})
    if args.has_key?(:of_type)
      @errors[args[:of_type]] = []
    else
      @errors = {}
    end
  end

  # [Motel::Location] of the station in its parent solar system
  attr_reader :location

  # Set location of station in its parent solar system
  #
  # Will set the parent of the specified location to correspond to the solar system's location object
  # @param [Motel::Location] val location to assign to the station
  def location=(val)
    @location = val
    @location.parent = parent.location unless parent.nil? || @location.nil?
  end

  # [STATION_TYPE] General category / classification of station
  attr_reader :type

  # Set station type
  #
  # Assigns size to that corresponding to type
  # @param [STATION_TYPE] val type to assign to the station
  def type=(val)
    @type = val
    @size = STATION_SIZES[val]
  end

  # [Cosmos::SolarSystem] the station is in
  attr_reader :solar_system

  # [String] name of the solar system.
  #
  # Used to reference the solar_system w/out having to pass
  # the entire system around
  attr_reader :system_name

  # Set solar system the station is in
  #
  # Assigns the parent of the station's location to the location corresponding to the new solar system
  # @param [Cosmos::SolarSystem] val solar system parent to assign to the station
  def solar_system=(val)
    @solar_system = val
    @system_name = @solar_system.name
    @location.parent = parent.location unless parent.nil? || @location.nil?
  end

  # Distance station travels during a single movement cycle
  #
  # TODO make stations stationary in a system ?
  attr_accessor :movement_speed

  # Mapping of ids of resources contained in the station to quantities contained
  attr_reader :resources

  # Max distance a ship can be from station to dock with it
  attr_reader :docking_distance

  # Max cargo capacity of station
  # @see #cargo_quantity
  attr_accessor :cargo_capacity

  # Distance away from the station which new entities are constructed
  attr_reader :construction_distance

  # General station classification, used to determine
  # a station's capabilities
  STATION_TYPES = [:defense, :offense, :mining, :exploration, :science,
                   :technology, :manufacturing, :commerce]

  # Mapping of station types to default sizes
  STATION_SIZES = {:defense => 35, :offense => 35, :mining => 27,
                   :exploration => 20, :science => 20,
                   :technology => 20, :manufacturing => 40,
                   :commerce => 30}

  # Return the cost to construct a station of the specified type
  #
  # TODO right now just return a fixed cost for every station, eventually make more variable
  #
  # @param [STATION_TYPE] type type of station which to return construction cost
  # @return [Integer] quantity of resources required to construct station
  def self.construction_cost(type)
    100
  end

  # Station initializer
  # @param [Hash] args hash of options to initialize attack command with
  # @option args [String] :id,'id' id to assign to the station
  # @option args [String] :user_id,'user_id' id of user that owns the station
  # @option args [STATION_TYPE] :type,'type' type to assign to station, if not set a random type will be assigned
  # @option args [Integer] :size,'size' size to assign to station, if not set will be set to size corresponding to type
  # @option args [Hash<Symbol,Array<String>] :errors,'errors' operation errors to set on station
  # @option args [Hash<String,Int>] :resources,'resources' hash of resource ids to quantities contained in the station
  # @option args [Cosmos::SolarSystem] :solar_system,'solar_system' solar system which the station is in
  # @option args [Motel::Location] :location,'location' location of the station in the solar system
  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @type     = args['type']     || args[:type]
    @type     = @type.intern if !@type.nil? && @type.is_a?(String)
    @type     = STATION_TYPES[rand(STATION_TYPES.size)] if @type.nil?
    @user_id  = args['user_id']  || args[:user_id]
    @size     = args['size']     || args[:size] || (@type.nil? ? nil : STATION_SIZES[@type])

    @errors   = args[:errors]    || args['errors'] || {}

    @resources = args[:resources] || args['resources'] || {}

    # TODO make variable
    @movement_speed = 5
    @cargo_capacity = 10000
    @docking_distance = 100
    @transfer_distance = 100
    @construction_distance = 50
    @hp = 0

    if args.has_key?('solar_system') || args.has_key?(:solar_system)
      self.solar_system = args['solar_system'] || args[:solar_system]
    elsif args.has_key?('system_name') || args.has_key?(:system_name)
      @system_name = args['system_name'] || args[:system_name]
      # TODO would rather not access the cosmos registry directly here
      solar_system = Cosmos::Registry.instance.find_entity(:type => :solarsystem,
                                                           :name => @system_name)
      self.solar_system = solar_system unless solar_system.nil?
    end

    self.location = args['location'] || args[:location]

    self.location = Motel::Location.new if @location.nil?
    @location.x = 0 if @location.x.nil?
    @location.y = 0 if @location.y.nil?
    @location.z = 0 if @location.z.nil?
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
  # * type is one of valid STATION_TYPES
  # * size corresponds to the correct value for type
  # * solar system is set to Cosmos::SolarSystem
  # * resources is a hash of resource ids to quantities
  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) &&
    !@user_id.nil? && @user_id.is_a?(String) && # ensure user id corresponds to actual user ?
    !@type.nil? && STATION_TYPES.include?(@type) &&
    !@size.nil? && @size == STATION_SIZES[@type] &&
    !@solar_system.nil? && @solar_system.is_a?(Cosmos::SolarSystem) &&
    @resources.is_a?(Hash) && @resources.select { |id,q| !id.is_a?(String) || !(q.is_a?(Integer) || q.is_a?(Float)) }.empty? # TODO verify resources are valid in context of ship
    # TODO validate cargo properties when they become variable
  end

  # Return true / false indicating station permits specified ship to dock
  #
  # @param [Manufactured::Ship] ship ship which to give or deny docking clearance
  # @return [true,false] indicating if ship is allowed to dock at station
  def dockable?(ship)
    # TODO at some point we may want to limit
    # the number of ships able to be ported at a station at a given time,
    # restrict this via station type, add a toggleable flag, etc
    (ship.location.parent.id == @location.parent.id) &&
    (ship.location - @location) <= @docking_distance &&
    !ship.docked?
  end

  # Return stations's parent solar system
  #
  # @return [Cosmos::SolarSystem]
  def parent
    return self.solar_system
  end

  # Set stations's parent solar system
  # @param [Cosmos::SolarSystem] system solar system to assign to station
  def parent=(system)
    self.solar_system = system
  end

  # Add specified quantity of resource specified by id to station
  #
  # @param [String] resource_id id of resource being added
  # @param [Integer] quantity amount of resource to add
  # @raise [Omega::OperationError] if station cannot accept specified quantity of resource
  def add_resource(resource_id, quantity)
    raise Omega::OperationError, "station cannot accept resource" unless can_accept?(resource_id, quantity) # should we define an exception heirarchy local to manufactured so as not to pull in omega here?
    @resources[resource_id] ||= 0
    @resources[resource_id] += quantity
  end

  # Remove specified quantity of resource specified by id from station
  #
  # @param [String] resource_id id of resource being removed
  # @param [Integer] quantity amount of resource to remove
  # @raise [Omega::OperationError] if station does not have the specified quantity of resource
  def remove_resource(resource_id, quantity)
    unless @resources.has_key?(resource_id) && @resources[resource_id] >= quantity
      raise Omega::OperationError, "ship does not contain specified quantity of resource" 
    end
    @resources[resource_id] -= quantity
    @resources.delete(resource_id) if @resources[resource_id] <= 0
  end

  # Determine the current cargo quantity
  #
  # @return [Integer] representing the amount of resource/etc in the station
  def cargo_quantity
    q = 0
    @resources.each { |id, quantity|
      q += quantity
    }
    q
  end

  # Return boolean if station can transfer specified quantity of resource
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

  # Return boolean indicating if station can accpt the specified quantity
  # of the resource specified by id
  #
  # @param [String] resource_id id of resource being transfered
  # @param [Integer] quantity amount of resource being transfered
  def can_accept?(resource_id, quantity)
    self.cargo_quantity + quantity <= @cargo_capacity
  end

  # Return true / false indiciating if station can construct entity specified by args.
  #
  # Also sets @errors[:construction] if station cannot construct entity.
  #
  # @param [Hash] args args which will be passed to {#construct} to construct entity
  # @return [true,false] indicating if station can construct entity
  def can_construct?(args = {})
    entity_type = args[:entity_type]
    cargs       = {}
    cclass      = nil

    if entity_type == "Manufactured::Ship"
      cargs = {:id => Motel.gen_uuid,
               :type => :frigate}.merge(args)
      cclass = Manufactured::Ship
    elsif entity_type == "Manufactured::Station"
      cargs = {:id => Motel.gen_uuid,
               :type => :manufacturing}.merge(args)
      cclass = Manufactured::Station
    end

    # TODO also check if entity can be constructed in system ?
    @errors[:construction] ||= []
    if @type != :manufacturing
      @errors[:construction] << "not manufacturing station"
    elsif cclass.nil?
      @errors[:construction] << "cannot construct entity of type #{entity_type}"
    elsif cargo_quantity < cclass.construction_cost(cargs[:type])
      @errors[:construction] << "insufficient resources"
    else
      return true
    end
    return false
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
    # verify station is of manufacturing type
    return nil unless @type == :manufacturing

    # FIXME construction time/delay
    entity_type = args[:entity_type]
    entity      = nil
    cargs       = {}
    cclass      = nil

    if entity_type == "Manufactured::Ship"
      cargs = {:id => Motel.gen_uuid,
               :type => :frigate}.merge(args)
      cclass = Manufactured::Ship
    elsif entity_type == "Manufactured::Station"
      cargs = {:id => Motel.gen_uuid,
               :type => :manufacturing}.merge(args)
      cclass = Manufactured::Station
    end

    return nil if cclass.nil?

    # verify enough resources are locally present to construct entity
    cost = cclass.construction_cost(cargs[:type])
    if cargo_quantity < cost
      return nil
    end

    # remove resources from the station
    # TODO when entities are mapped to specific resources and quantities
    # needed to construct them, we can be more discreminate here
    remaining = cost
    @resources.each { |id,quantity|
      if quantity >= remaining
        @resources[id] -= remaining
        break
      else
        remaining -= quantity
        @resources[id] = 0
      end
    }

    # instantiate the new entity
    entity = cclass.new cargs unless cclass.nil?

    unless entity.nil?
      entity.parent = self.parent

      entity.location.parent = self.location.parent
      entity.location.parent_id = self.location.parent.id

      # allow user to specify coordinates unless too far away
      # in which case, construct at closest location to specified location withing construction distance
      distance = entity.location - self.location
      if distance > @construction_distance
        dx = (entity.location.x - self.location.x) / distance
        dy = (entity.location.y - self.location.y) / distance
        dz = (entity.location.z - self.location.z) / distance
        entity.location.x = dx * @construction_distance
        entity.location.y = dy * @construction_distance
        entity.location.z = dz * @construction_distance
      end
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
          :errors => errors,
          :docking_distance => @docking_distance,
          :location => @location,
          :system_name => (@solar_system.nil? ? @system_name : @solar_system.name),
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
