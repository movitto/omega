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
    name   = args[:name]
    galaxy = args[:galaxy]

    @star = Star.new :solar_system => self
    @planets = []

    # TODO parameterize planet creation
    0.upto(rand(10)){ |i|
      @planets << Planet.new(:solar_system => self)
    }

    # TODO generate random location
    # @location.x = @location.y = @location.z = 
  end

  def add_child(planet)
    # TODO rails exception unless planet.is_a? Planet
    @planets << planet
  end
end
end
