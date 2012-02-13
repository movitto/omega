# Cosmos Planet definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Planet
  attr_reader :name
  attr_reader :location

  attr_reader :solar_system
  attr_reader :moons

  def initialize(args = {})
    @name = args['name'] || args[:name]
    @solar_system = args['solar_system']
    @moons = args.has_key?('moons') ? args['moons'] : []

    if args.has_key?('location')
      @location = args['location']
    else
      @location = Motel::Location.new
      # TODO generate random coordiantes ?
      #@location.x = @location.y = @location.z = 0
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
