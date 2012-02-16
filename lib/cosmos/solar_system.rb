# Cosmos SolarSystem definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class SolarSystem
  # maximum size of the system in any given direction from center
  MAX_SIZE = 100

  attr_reader :name
  attr_reader :size
  attr_reader :location

  attr_reader :galaxy
  attr_reader :star
  attr_reader :planets

  def initialize(args = {})
    @name = args['name'] || args[:name]
    @location = args['location'] || args[:location]
    @galaxy = args['galaxy']
    @star = args.has_key?('star') ? args['star'] : nil
    @planets = args.has_key?('planets') ? args['planets'] : []

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

  def add_child(child)
    if child.is_a? Planet
      @planets << child 
    elsif child.is_a? Star
      @star = child
    end
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
