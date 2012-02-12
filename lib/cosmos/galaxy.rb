# Cosmos Galaxy definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Galaxy
  attr_reader :name
  attr_reader :location
  attr_reader :solar_systems

  def initialize(args = {})
    @name = args[:name]

    @solar_systems = []
    @location = Motel::Location.new
    @location.x = @location.y = @location.z = 0

    # TODO parameterize system creation
    0.upto(rand(10)) { |i|
      @solar_systems <<  SolarSystem.new(:name   => "#{name}-system-#{i}",
                                         :galaxy => self)
    }
  end

  def add_child(solar_system)
    # TODO rails exception unless solar_system.is_a? SolarSystem
    @solar_systems << solar_system
  end
end
end
