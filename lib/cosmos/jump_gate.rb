# Cosmos JumpGate definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class JumpGate
  attr_reader :solar_system
  attr_reader :endpoint
  attr_accessor :location

  def initialize(args = {})
    @solar_system = args['solar_system'] || args[:solar_system]
    @endpoint     = args['endpoint']     || args[:endpoint]
    @location     = args['location']     || args[:location]

    # TODO would rather not access the cosmos registry directly here
    if @solar_system.is_a?(String)
      tsolar_system = Cosmos::Registry.instance.find_entity(:type => :solarsystem,
                                                            :name => @solar_system)
      @solar_system = tsolar_system unless tsolar_system.nil?
    end

    if @endpoint.is_a?(String)
      tendpoint = Cosmos::Registry.instance.find_entity(:type => :solarsystem,
                                                        :name => @endpoint)
      @endpoint = tendpoint unless tendpoint.nil?
    end

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
        {:solar_system => (@solar_system.is_a?(String) ?
                           @solar_system : @solar_system.name),
         :endpoint     => (@endpoint.is_a?(String)     ?
                           @endpoint : @endpoint.name),
         :location     => @location}
    }.to_json(*a)
  end

  def to_s
    "jump_gate-#{solar_system}-#{endpoint}"
  end

  def self.json_create(o)
    jump_gate = new(o['data'])
    return jump_gate
  end

end
end
