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
  attr_reader :location

  attr_reader :solar_system
  attr_reader :moons

  def initialize(args = {})
    @name = args['name'] || args[:name]
    @location = args['location'] || args[:location]
    @solar_system = args['solar_system']
    @moons = args.has_key?('moons') ? args['moons'] : []

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end

    if args.has_key?('size')
      @size = args['size']
    else
      # TODO generate random size from MAX?
      @size = MAX_SIZE
    end
  end

  def add_child(moon)
    # TODO rails exception unless moon.is_a? Moon
    @moons << moon
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :location => @location, :moons => @moons}
     }.to_json(*a)
   end

   def self.json_create(o)
     planet = new(o['data'])
     return planet
   end

end
end
