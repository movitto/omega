# Manufactured Ship definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured
class Ship
  # ship properties
  attr_accessor :id
  attr_accessor :user_id
  attr_accessor :size

  attr_reader :location
  def location=(val)
    @location = val
    @location.parent = parent.location unless parent.nil? || @location.nil?
  end

  attr_reader :type
  def type=(val)
    @type = val
    @size = SHIP_SIZES[val]
  end

  # system ship is in
  attr_reader :solar_system
  def solar_system=(val)
    @solar_system = val
    @location.parent = parent.location unless parent.nil? || @location.nil?
  end

  # list of callbacks to invoke on certain events relating to ship
  attr_accessor :notification_callbacks

  # attack/defense properties
  attr_accessor :attack_distance
  attr_accessor :attack_rate  # attacks per second
  attr_accessor :damage_dealt
  attr_accessor :hp

  # mining properties
  attr_accessor :mining_rate  # times to mine per second
  attr_accessor :mining_quantity # how much we extract each time we mine
  attr_accessor :mining_distance # max distance entities can be apart to mine

  # station ship is docked to, nil if not docked
  attr_reader :docked_at

  # resource source ship is mining, nil if not mining
  attr_reader :mining

  # map of resources contained in the ship to quantities
  attr_reader :resources

  # cargo properties
  attr_accessor :cargo_capacity
  # see cargo_quantity below

  SHIP_TYPES = [:frigate, :transport, :escort, :destroyer, :bomber, :corvette,
                :battlecruiser, :exploration, :mining]

  ATTACK_SHIP_TYPES = [:escort, :destroyer, :bomber, :corvette, :battlecruiser]

  # mapping of ship types to default sizes
  SHIP_SIZES = {:frigate => 35,  :transport => 25, :escort => 20,
                :destroyer => 30, :bomber => 25, :corvette => 25,
                :battlecruiser => 35, :exploration => 23, :mining => 25}

  # TODO right now just return a fixed cost for every ship, eventually make more variable
  def self.construction_cost(type)
    100
  end

  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @user_id  = args['user_id']  || args[:user_id]
    @type     = args['type']     || args[:type]
    @type     = @type.intern if !@type.nil? && @type.is_a?(String)
    @type     = SHIP_TYPES[rand(SHIP_TYPES.size)] if @type.nil?
    @size     = args['size']     || args[:size] || (@type.nil? ? nil : SHIP_SIZES[@type])
    @docked_at= args['docked_at']|| args[:docked_at]

    @notification_callbacks = args['notifications'] || args[:notifications] || []
    @resources = args[:resources] || args['resources'] || {}

    # FIXME make variable
    @cargo_capacity = 100
    @attack_distance = 100
    @attack_rate  = 0.5
    @damage_dealt = 2
    @hp           = 10
    @mining_rate  = 0.5
    @mining_quantity = 5
    @mining_distance = 100
    @transfer_distance = 100

    @mining    = nil

    self.solar_system = args[:solar_system] || args['solar_system']

    # location should be set after solar system so parent is set correctly
    self.location = args['location'] || args[:location]

    if @location.nil?
      self.location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end

    @location.movement_strategy = args[:movement_strategy] if args.has_key?(:movement_strategy)
  end

  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) &&
    !@user_id.nil? && @user_id.is_a?(String) && # ensure user id corresponds to actual user ?
    !@type.nil? && SHIP_TYPES.include?(@type) &&
    !@size.nil? && @size == SHIP_SIZES[@type] &&
    (@docked_at.nil? || @docked_at.is_a?(Manufactured::Station)) && # TODO verify within docking distance of station
    (@mining.nil? || @mining.is_a?(Cosmos::Asteroid)) && # TODO verify withing mining distance of target & update as other mining entities are supported
    !@solar_system.nil? && @solar_system.is_a?(Cosmos::SolarSystem) &&
    @notification_callbacks.is_a?(Array) && @notification_callbacks.select { |nc| !nc.kind_of?(Manufactured::Callback) }.empty? && # TODO ensure validity of callbacks
    @resources.is_a?(Hash) && @resources.select { |id,q| !id.is_a?(String) || !(q.is_a?(Integer) || q.is_a?(Float)) }.empty? # TODO verify resources are valid in context of ship
    # TODO validate cargo, mining, attack properties when they become variable
  end

  def parent
    return @solar_system
  end

  def parent=(system)
    self.solar_system = system
  end

  def can_attack?(entity)
    ATTACK_SHIP_TYPES.include?(@type) && !self.docked? &&
    (@location.parent.id == entity.location.parent.id) &&
    (@location - entity.location) <= @attack_distance
  end

  def can_mine?(resource_source)
    # TODO eventually filter per specific resource mining capabilities
    @type == :mining && !self.docked? &&
    (@location.parent.id == resource_source.entity.location.parent.id) &&
    (@location - resource_source.entity.location) <= @mining_distance &&
    (cargo_quantity + @mining_quantity) <= @cargo_capacity
  end

  def docked?
    !@docked_at.nil?
  end

  def dock_at(station)
    @docked_at = station
  end

  def undock
    # TODO check to see if station has given ship undocking clearance
    @docked_at = nil
  end

  def mining?
    !@mining.nil?
  end

  def start_mining(resource_source)
    # FIXME ensure ship / resource_source are within mining distance
    #       + ship is has mining capabilities
    #       + ship isn't full
    # TODO resource_source.add_sink(ship)
    @mining = resource_source
  end

  def stop_mining
    @mining = nil
  end

  def add_resource(resource_id, quantity)
    # TODO raise error if cargo_quantity >= cargo_capacity
    @resources[resource_id] ||= 0
    @resources[resource_id] += quantity
  end

  def remove_resource(resource_id, quantity)
    return unless @resources.has_key?(resource_id) ||# TODO throw exception?
                  @resources[resource_id] >= quantity
    @resources[resource_id] -= quantity
    @resources.delete(resource_id) if @resources[resource_id] <= 0
  end

  def cargo_quantity
    q = 0
    @resources.each { |id, quantity|
      q += quantity
    }
    q
  end

  def can_transfer?(to_entity, resource_id, quantity)
    @id != to_entity.id &&
    @resources.has_key?(resource_id) &&
    @resources[resource_id] >= quantity &&
    (@location.parent.id == to_entity.location.parent.id) &&
    ((@location - to_entity.location) <= @transfer_distance)
  end

  def can_accept?(resource_id, quantity)
    self.cargo_quantity + quantity <= @cargo_capacity
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :user_id => user_id,
         :type => type, :size => size,
         :docked_at => @docked_at,
         :location => @location,
         :solar_system => @solar_system,
         :resources => @resources,
         :notifications => @notification_callbacks}
    }.to_json(*a)
  end

  def to_s
    "ship-#{@id}"
  end

  def self.json_create(o)
    ship = new(o['data'])
    return ship
  end

end
end
