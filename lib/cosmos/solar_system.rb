# Cosmos SolarSystem definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class SolarSystem
  attr_reader :name
  attr_reader :location

  attr_reader :galaxy
  attr_reader :star
  attr_reader :planets
  attr_reader :jump_gates

  def id
    return @name
  end

  def initialize(args = {})
    @name       = args['name']       || args[:name]
    @location   = args['location']   || args[:location]
    @star       = args['star']       || nil
    @galaxy     = args['galaxy']
    @planets    = args['planets']    || []
    @jump_gates = args['jump_gates'] || []

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def add_child(child)
    if child.is_a? Planet
      @planets << child 
    elsif child.is_a? JumpGate
      @jump_gates << child
    elsif child.is_a? Star
      @star = child
    end
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :location => @location,
          :star => @star, :planets => @planets, :jump_gates => @jump_gates}
     }.to_json(*a)
   end

   def self.json_create(o)
     galaxy = new(o['data'])
     return galaxy
   end

end
end
