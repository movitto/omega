# Cosmos Moon definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Moon
  attr_reader :name
  attr_reader :location

  attr_reader :planet

  def initialize(args = {})
    name   = args[:name]
    planet = args[:planet]

    # TODO generate random location
    # @location.x = @location.y = @location.z = 
  end
end
end
