# Cosmos Moon definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Moon
  attr_reader :name
  attr_accessor :location

  attr_reader :planet

  def initialize(args = {})
    @name = args['name'] || args[:name]
    @location = args['location'] || args[:location]
    @planet = args['planet']

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def has_children?
    false
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :location => @location}
     }.to_json(*a)
   end

   def to_s
     "moon-#{name}"
   end

   def self.json_create(o)
     moon = new(o['data'])
     return moon
   end

end
end
