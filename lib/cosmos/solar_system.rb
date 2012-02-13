# Cosmos SolarSystem definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class SolarSystem
  attr_reader :name
  attr_reader :location

  attr_reader :galaxy
  attr_reader :star
  attr_reader :planets

  def initialize(args = {})
    @name = args['name'] || args[:name]
    @galaxy = args['galaxy']
    @star = args.has_key?('star') ? args['star'] : Star.new(:solar_system => self)
    @planets = args.has_key?('planets') ? args['planets'] : []

    if args.has_key?('location')
      @location = args['location']
    else
      @location = Motel::Location.new
      # TODO generate random coordiantes ?
      #@location.x = @location.y = @location.z = 0
    end
  end

  def add_child(planet)
    # TODO rails exception unless planet.is_a? Planet
    @planets << planet
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :location => @location, :star => @star, :planets => @planets}
     }.to_json(*a)
   end

   def self.json_create(o)
     galaxy = new(o['data'])
     return galaxy
   end

end
end
