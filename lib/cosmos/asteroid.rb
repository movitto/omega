# Cosmos Asteroid definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Asteroid
  # size of the asteroid
  MAX_ASTEROID_SIZE = 20
  MIN_ASTEROID_SIZE = 10

  attr_reader :name
  attr_reader :size
  attr_reader :color
  attr_accessor :location

  attr_reader :solar_system

  def initialize(args = {})
    @name     = args['name']     || args[:name]
    @location = args['location'] || args[:location]
    @color    = args['color']    || args[:color]    || ("%06x" % (rand * 0xffffff))
    @size     = args['size']     || args[:size]     || (rand(MAX_ASTEROID_SIZE-MIN_ASTEROID_SIZE) + MIN_ASTEROID_SIZE)

    @solar_system = args['solar_system'] || args[:solar_system]

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def has_children?
    false
  end

  def to_s
    "asteroid-#{@name}"
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :color => color, :size => size, :location => @location}
     }.to_json(*a)
   end

   def self.json_create(o)
     asteroid = new(o['data'])
     return asteroid
   end

end
end
