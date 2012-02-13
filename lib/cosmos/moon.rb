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
    @name = args['name'] || args[:name]
    @planet = args['planet']

    if args.has_key?('location')
      @location = args['location']
    else
      @location = Motel::Location.new
      # TODO generate random coordiantes ?
      #@location.x = @location.y = @location.z = 0
    end
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :location => @location}
     }.to_json(*a)
   end

   def self.json_create(o)
     moon = new(o['data'])
     return moon
   end

end
end
