# Manufactured Station definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured
class Station
  attr_reader :id
  attr_accessor :user_id
  attr_accessor :type
  attr_accessor :location
  attr_accessor :size

  attr_accessor :solar_system

  # map of resources contained in the station to quantities
  attr_reader :resources

  STATION_TYPES = [:defense, :offense, :mining, :exploration, :science,
                   :technology, :manufacturing, :commerce]

  STATION_SIZES = {:defense => 35, :offense => 35, :mining => 27,
                   :exploration => 20, :science => 20,
                   :technology => 20, :manufacturing => 40,
                   :commerce => 30}


  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @type     = args['type']     || args[:type]
    @type     = @type.intern if !@type.nil? && @type.is_a?(String)
    @location = args['location'] || args[:location]
    @user_id  = args['user_id']  || args[:user_id]
    @size     = args['size']     || args[:size] || (@type.nil? ? nil : STATION_SIZES[@type])

    @solar_system = args['solar_system'] || args[:solar_system]

    @resources = {}

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def parent
    return @solar_system
  end

  def parent=(system)
    @solar_system = system
  end

  def add_resource(resource, quantity)
    @resources[resource.id] ||= 0
    @resources[resource.id] += quantity
  end

  def remove_resource(resource, quantity)
    return unless @resources.has_key?(resource.id) ||# TODO throw exception?
                  @resources[resource.id] >= quantity
    @resources[resource.id] -= quantity
  end

  def to_s
    "station-#{@id}"
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:id => id, :user_id => user_id, :type => type, :size => size, :location => @location, :solar_system => @solar_system}
     }.to_json(*a)
   end

   def self.json_create(o)
     ship = new(o['data'])
     return ship
   end

end
end
