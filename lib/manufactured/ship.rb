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

  # system ship is in
  attr_accessor :solar_system

  # list of callbacks to invoke on certain events relating to ship
  attr_accessor :notification_callbacks

  # attack/defense properties
  attr_accessor :attack_rate  # attacks per second
  attr_accessor :damage_dealt
  attr_accessor :hp

  # station ship is docked to, nil if not docked
  attr_reader :docked_at

  SHIP_TYPES = [:frigate, :transport, :escort, :destroyer, :bomber, :corvette,
                :battlecruiser, :exploration]

  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @user_id  = args['user_id']  || args[:user_id]
    @type     = args['type']     || args[:type]
    @location = args['location'] || args[:location]

    @solar_system = args[:solar_system] || args['solar_system']

    @notification_callbacks = []

    # FIXME make variable
    @attack_rate  = 0.5
    @damage_dealt = 2
    @hp           = 10

    @docked_to = nil

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

  def dock_at(station)
    # FIXME ensure ship / station are within docking distance
    #       + other permission checks (eg if station has free ports, allows ship to dock)
    #       + ship isn't docked elsewhere
    # TODO station.add_docked_ship(ship)
    @docked_at = station
  end

  def undock
    @docked_at = nil
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :user_id => user_id, :type => type, :docked_at => @docked_at, :location => @location, :solar_system => @solar_system}
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
