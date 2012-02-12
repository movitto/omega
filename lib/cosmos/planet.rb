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
    name   = args[:name]
    solar_system = args[:solar_system]

    @moons = []

    # TODO parameterize moon creation
    0.upto(rand(10)) { |i|
      @moons << Moon.new(:name   => "#{name}-moon-#{i}",
                         :solar_system => self)
    }

    # TODO generate random location
    # @location.x = @location.y = @location.z = 
  end

  def add_child(moon)
    # TODO rails exception unless moon.is_a? Moon
    @moons << moon
  end

end
end
