# Cosmos Galaxy definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Galaxy
  attr_accessor :name
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

  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    @solar_systems.is_a?(Array) && @solar_systems.find { |s| !s.is_a?(Cosmos::SolarSystem) || !s.valid? }.nil?
  end

  # does not accept any resources
  def accepts_resource?(res)
    false
  end

  def self.parent_type
    :universe
  end

  def self.remotely_trackable?
    true
  end

  def parent
    nil
  end

  def parent=(val)
    # intentionally left empty as no need to add registry here
  end

  def children
    @solar_systems
  end

  def add_child(solar_system)
    raise ArgumentError, "child must be a solar system" if !solar_system.is_a?(Cosmos::SolarSystem)
    raise ArgumentError, "solar system name #{solar_system.name} is already taken" if @solar_systems.find { |s| s.name == solar_system.name }
    raise ArgumentError, "solar system #{solar_system} already added to galaxy" if @solar_systems.include?(solar_system)
    raise ArgumentError, "solar system #{solar_system} must be valid" unless solar_system.valid?
    solar_system.location.parent_id = location.id
    solar_system.parent = self
    @solar_systems << solar_system
    solar_system
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
