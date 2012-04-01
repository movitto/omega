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

    @background = "system#{rand(MAX_BACKGROUNDS-1)+1}"

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
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

  def each_child(&bl)
    bl.call star unless star.nil?
    @planets.each { |planet|
      bl.call planet
      planet.each_child &bl
    }
    @jump_gates.each { |gate|
      bl.call gate
    }
    @asteroids.each { |asteroid|
      bl.call asteroid
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
          :asteroids => @asteroids}
     }.to_json(*a)
   end

   def self.json_create(o)
     galaxy = new(o['data'])
     return galaxy
   end

end
end
