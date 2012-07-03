# Cosmos Star definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Star
  attr_accessor :name
  attr_accessor :location
  attr_reader   :color
  attr_reader   :size

  attr_reader :solar_system

  STAR_COLORS = ["FFFF00"]
  MAX_STAR_SIZE = 55
  MIN_STAR_SIZE = 40

  def initialize(args = {})
    @name = args['name'] || args[:name]
    @location = args['location'] || args[:location]
    @solar_system = args['solar_system'] || args[:solar_system]
    @color = args['color'] || args[:color] || STAR_COLORS[rand(STAR_COLORS.length)]
    @size  = args['size']  || args[:size]  || (rand(MAX_STAR_SIZE - MIN_STAR_SIZE) + MIN_STAR_SIZE)

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::SolarSystem)) &&
    (@size.is_a?(Integer) || @size.is_a?(Float)) && @size <= MAX_STAR_SIZE && @size >= MIN_STAR_SIZE &&
    @color.is_a?(String) && STAR_COLORS.include?(@color)
  end

  def self.parent_type
    :solarsystem
  end

  def self.remotely_trackable?
    false
  end

  def parent
    @solar_system
  end

  def parent=(solar_system)
    @solar_system = solar_system
  end

  def has_children?
    false
  end

  def to_s
    "star-#{@name}"
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :color => @color, :size => @size, :location => @location}
     }.to_json(*a)
   end

   def self.json_create(o)
     star = new(o['data'])
     return star
   end
end
end
