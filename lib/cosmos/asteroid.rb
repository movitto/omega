# Cosmos Asteroid definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Asteroid
  # size of the asteroid
  MAX_ASTEROID_SIZE = 20
  MIN_ASTEROID_SIZE = 10

  attr_accessor :name
  attr_reader :size
  attr_reader :color
  attr_accessor :location

  attr_accessor :solar_system

  def initialize(args = {})
    @name     = args['name']     || args[:name]
    @location = args['location'] || args[:location]
    @color    = args['color']    || args[:color]    || ("%06x" % (rand * 0xffffff))
    @size     = args['size']     || args[:size]     || (rand(MAX_ASTEROID_SIZE-MIN_ASTEROID_SIZE) + MIN_ASTEROID_SIZE)

    @solar_system = args['solar_system'] || args[:solar_system]

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::SolarSystem)) &&
    (@size.is_a?(Integer) || @size.is_a?(Float)) && @size <= MAX_ASTEROID_SIZE && @size >= MIN_ASTEROID_SIZE &&
    @color.is_a?(String) && !/^[a-fA-F0-9]{6}$/.match(@color).nil?
  end

  def self.parent_type
    :solarsystem
  end

  def self.remotely_trackable?
    false
  end

  def parent
    @solar_system
  end

  def parent=(solar_system)
    @solar_system = solar_system
  end

  def has_children?
    false
  end

  def to_s
    "asteroid-#{@name}"
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :color => color, :size => size, :location => @location}
     }.to_json(*a)
   end

   def self.json_create(o)
     asteroid = new(o['data'])
     return asteroid
   end

end
end
