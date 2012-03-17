# Cosmos Planet definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Planet
  # maximum size of the planet
  MAX_SIZE = 10

  attr_reader :name
  attr_reader :size
  attr_reader :color
  attr_accessor :location

  attr_reader :solar_system
  attr_reader :moons

  def initialize(args = {})
    @name     = args['name']     || args[:name]
    @location = args['location'] || args[:location]
    @color    = args['color']    || args[:color]    || ("%06x" % (rand * 0xffffff))
    @size     = args['size']     || args[:size]     || MAX_SIZE # TODO generate random size from MAX?

    @moons        = args['moons'] || []
    @solar_system = args['solar_system']

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def add_child(moon)
    # TODO rails exception unless moon.is_a? Moon
    moon.location.parent_id = location.id
    @moons << moon
  end

  def has_children?
    @moons.size > 0
  end

  def each_child(&bl)
    @moons.each { |m|
      bl.call m
    }
  end

  def to_s
    "planet-#{@name}"
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :color => color, :location => @location, :moons => @moons}
     }.to_json(*a)
   end

   def self.json_create(o)
     planet = new(o['data'])
     return planet
   end

end
end
