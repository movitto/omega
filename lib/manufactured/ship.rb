# Manufactured Ship definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured
class Ship
  # ship properties
  attr_reader   :id
  attr_reader   :user_id
  attr_reader   :type
  attr_accessor :location

  # system ship is in
  attr_reader :solar_system

  # list of callbacks to invoke on certain events relating to ship
  attr_accessor :notification_callbacks

  # attack/defense properties
  attr_accessor :attack_rate  # attacks per second
  attr_accessor :damage_dealt
  attr_accessor :hp

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

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :user_id => user_id, :type => type, :location => @location, :solar_system => @solar_system}
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
