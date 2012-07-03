# Cosmos Planet definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Planet
  # size of the planet
  MAX_PLANET_SIZE = 20
  MIN_PLANET_SIZE = 10

  attr_accessor :name
  attr_reader :size
  attr_reader :color
  attr_accessor :location

  attr_reader :solar_system
  attr_reader :moons

  def initialize(args = {})
    @name     = args['name']     || args[:name]
    @location = args['location'] || args[:location]
    @color    = args['color']    || args[:color]    || ("%06x" % (rand * 0xffffff))
    @size     = args['size']     || args[:size]     || (rand(MAX_PLANET_SIZE-MIN_PLANET_SIZE) + MIN_PLANET_SIZE)

    @moons        = args['moons'] || []
    @solar_system = args['solar_system'] || args[:solar_system]

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end

    @location.movement_strategy = args[:movement_strategy] if args.has_key?(:movement_strategy)
  end

  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && #@location.movement_strategy.class == Motel::MovementStrategies::Elliptical &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::SolarSystem)) &&
    @moons.is_a?(Array) && @moons.find { |m| !m.is_a?(Cosmos::Moon) || !m.valid? }.nil? &&
    (@size.is_a?(Integer) || @size.is_a?(Float)) && @size <= MAX_PLANET_SIZE && @size >= MIN_PLANET_SIZE &&
    @color.is_a?(String) && !/^[a-fA-F0-9]{6}$/.match(@color).nil?
  end

  def self.parent_type
    :solarsystem
  end

  def self.remotely_trackable?
    false
  end

  def parent=(solar_system)
    @solar_system = solar_system
  end

  def children
    @moons
  end

  def add_child(moon)
    raise ArgumentError, "child must be a moon" if !moon.is_a?(Cosmos::Moon)
    raise ArgumentError, "moon name #{moon.name} is already taken" if @moons.find { |m| m.name == moon.name }
    raise ArgumentError, "moon #{moon} already added to planet" if @moons.include?(moon)
    raise ArgumentError, "moon #{moon} must be valid" unless moon.valid?
    moon.location.parent_id = location.id
    moon.parent = self
    @moons << moon
    moon
  end

  def remove_child(child)
    @moons.reject! { |ch| (child.is_a?(Cosmos::Moon) && ch == child) ||
                          (child == ch.name) }
  end

  def has_children?
    @moons.size > 0
  end

  def each_child(&bl)
    @moons.each { |m|
      bl.call self, m
    }
  end

  def movement_strategy=(strategy)
    @location.movement_strategy = strategy unless @location.nil?
  end

  def to_s
    "planet-#{@name}"
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :color => color, :size => size, :location => @location, :moons => @moons}
     }.to_json(*a)
   end

   def self.json_create(o)
     planet = new(o['data'])
     return planet
   end

end
end
