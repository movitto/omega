# Cosmos Galaxy definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Galaxy
  attr_reader :name
  attr_accessor :location
  attr_reader :solar_systems

  MAX_BACKGROUNDS = 7
  attr_reader :background

  # if systems under this galaxy are tracked remotely,
  # name of the remote queue which to query for them
  attr_accessor :remote_queue

  def initialize(args = {})
    @name          = args['name']          || args[:name]
    @location      = args['location']      || args[:location]
    @solar_systems = args['solar_systems'] || []
    @remote_queue  = args['remote_queue']  || args[:remote_queue] || nil

    @background = "galaxy#{rand(MAX_BACKGROUNDS-1)+1}"


    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def self.parent_type
    :universe
  end

  def self.remotely_trackable?
    true
  end

  def children
    @solar_systems
  end

  def add_child(solar_system)
    # TODO rails exception unless solar_system.is_a? SolarSystem
    solar_system.location.parent_id = location.id
    @solar_systems << solar_system unless @solar_systems.include?(solar_system) || !solar_system.is_a?(Cosmos::SolarSystem)
  end

  def remove_child(child)
    @solar_systems.reject! { |ch| (child.is_a?(Cosmos::SolarSystem) && ch == child) ||
                                  (child == ch.name) }
  end

  def has_children?
    return @solar_systems.size > 0
  end

  def each_child(&bl)
    @solar_systems.each { |sys|
      bl.call self, sys
      sys.each_child &bl
    }
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => @name,
          :background => @background,
          :remote_queue => @remote_queue,
          :location => @location, :solar_systems => @solar_systems}
     }.to_json(*a)
   end

   def to_s
     "galaxy-#{@name}"
   end

   def self.json_create(o)
     galaxy = new(o['data'])
     return galaxy
   end
end
end
