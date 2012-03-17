# Cosmos Star definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Star
  attr_reader :name
  attr_accessor :location

  attr_reader :solar_system

  def initialize(args = {})
    @name = args['name'] || args[:name]
    @location = args['location'] || args[:location]
    @solar_system = args['solar_system']

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
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
         {:name => name, :location => @location}
     }.to_json(*a)
   end

   def self.json_create(o)
     star = new(o['data'])
     return star
   end
end
end
