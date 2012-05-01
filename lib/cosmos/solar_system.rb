# Cosmos SolarSystem definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class SolarSystem
  attr_reader :name
  attr_accessor :location

  attr_reader :galaxy
  attr_reader :star
  attr_reader :planets
  attr_reader :jump_gates
  attr_reader :asteroids

  MAX_BACKGROUNDS = 6
  attr_reader :background

  # if children under this system are tracked remotely,
  # name of the remote queue which to query for them
  attr_accessor :remote_queue

  def id
    return @name
  end

  def initialize(args = {})
    @name       = args['name']       || args[:name]
    @location   = args['location']   || args[:location]
    @star       = args['star']       || nil
    @galaxy     = args['galaxy']     || args[:galaxy]
    @planets    = args['planets']    || []
    @jump_gates = args['jump_gates'] || []
    @asteroids  = args['asteroids '] || []
    @remote_queue = args['remote_queue'] || args[:remote_queue] || nil

    @background = "system#{rand(MAX_BACKGROUNDS-1)+1}"


    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def self.parent_type
    :galaxy
  end

  def self.remotely_trackable?
    true
  end

  def children
    @planets + @jump_gates + @asteroids + (@star.nil? ? [] : [@star])
  end

  def add_child(child)
    child.location.parent_id = location.id
    if child.is_a? Planet
      @planets << child  unless @planets.include?(child)
    elsif child.is_a? JumpGate
      @jump_gates << child unless @jump_gates.include?(child)
    elsif child.is_a? Asteroid
      @asteroids << child unless @asteroids.include?(child)
    elsif child.is_a? Star
      @star = child
    end
  end

  def remove_child(child)
    @planets.reject! { |ch| (child.is_a?(Cosmos::Planet) && ch == child) ||
                            (child == ch.name) }
    @jump_gates.reject! { |ch| (child.is_a?(Cosmos::JumpGate) && ch == child) } # TODO compare string against jg.endpoint.name ?
    @asteroids.reject!  { |ch| (child.is_a?(Cosmos::Asteroid) && ch == child) ||
                               (child == ch.name) }
    @star = nil if (child.is_a?(Cosmos::Star) && @star == child) || (!@star.nil? && child == @star.name)
  end

  def each_child(&bl)
    bl.call self, star unless star.nil?
    @planets.each { |planet|
      bl.call self, planet
      planet.each_child &bl
    }
    @jump_gates.each { |gate|
      bl.call self, gate
    }
    @asteroids.each { |asteroid|
      bl.call self, asteroid
    }
  end

  def has_children?
    true
  end

  def to_s
    "solar_system-#{@name}"
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :location => @location, :background => @background,
          :star => @star, :planets => @planets, :jump_gates => @jump_gates,
          :asteroids => @asteroids, :remote_queue => remote_queue}
     }.to_json(*a)
   end

   def self.json_create(o)
     galaxy = new(o['data'])
     return galaxy
   end

end
end
