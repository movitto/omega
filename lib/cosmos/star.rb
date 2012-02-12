# Cosmos Star definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Star
  attr_reader :name
  attr_reader :location

  attr_reader :solar_system

  def initialize(args = {})
    name   = args[:name]
    solar_system = args[:solar_system]

    @location = Motel::Location.new
    @location.x = @location.y = @location.z = 0
  end
end
end
