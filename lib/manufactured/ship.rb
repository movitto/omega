# Manufactured Ship definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured
class Ship
  # ship properties
  attr_reader   :id
  attr_accessor :user_id
  attr_accessor :type
  attr_accessor :location
  attr_accessor :size

  # system ship is in
  attr_accessor :solar_system

  # list of callbacks to invoke on certain events relating to ship
  attr_accessor :notification_callbacks

  # attack/defense properties
  attr_accessor :attack_rate  # attacks per second
  attr_accessor :damage_dealt
  attr_accessor :hp

  # mining properties
  attr_accessor :mining_rate  # times to mine per second
  attr_accessor :mining_quantity # how much we extract each time we mine

  # station ship is docked to, nil if not docked
  attr_reader :docked_at

  # resource source ship is mining, nil if not mining
  attr_reader :mining

  # map of resources contained in the ship to quantities
  attr_reader :resources

  SHIP_TYPES = [:frigate, :transport, :escort, :destroyer, :bomber, :corvette,
                :battlecruiser, :exploration]

  # mapping of ship types to default sizes
  SHIP_SIZES = {:frigate => 35,  :transport => 25, :escort => 20,
                :destroyer => 30, :bomber => 25, :corvette => 25,
                :battlecruiser => 35, :exploration => 23}

  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @user_id  = args['user_id']  || args[:user_id]
    @type     = args['type']     || args[:type]
    @type     = @type.intern if !@type.nil? && @type.is_a?(String)
    @location = args['location'] || args[:location]
    @size     = args['size']     || args[:size] || (@type.nil? ? nil : SHIP_SIZES[@type])

    @solar_system = args[:solar_system] || args['solar_system']

    @notification_callbacks = []
    @resources = {}

    # FIXME make variable
    @attack_rate  = 0.5
    @damage_dealt = 2
    @hp           = 10
    @mining_rate  = 0.5
    @mining_quantity = 5

    @docked_to = nil
    @mining    = nil

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def parent
    return @solar_system
  end

  def parent=(system)
    @solar_system = system
  end

  def docked?
    !@docked_at.nil?
  end

  def dock_at(station)
    # FIXME ensure ship / station are within docking distance
    #       + other permission checks (eg if station has free ports, allows ship to dock)
    #       + ship isn't docked elsewhere
    # TODO station.add_docked_ship(ship)
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

  def add_resource(resource, quantity)
    @resources[resource.id] ||= 0
    @resources[resource.id] += quantity
  end

  def remove_resource(resource, quantity)
    return unless @resources.has_key?(resource.id) ||# TODO throw exception?
                  @resources[resource.id] >= quantity
    @resources[resource.id] -= quantity
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :user_id => user_id,
         :type => type, :size => size,
         :docked_at => @docked_at,
         :location => @location,
         :solar_system => @solar_system}
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
