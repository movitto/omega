# Cosmos JumpGate definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class JumpGate
  attr_accessor :solar_system
  attr_accessor :endpoint
  attr_accessor :location

  # max distance in any direction around
  # gate which entities can trigger it
  attr_reader   :trigger_distance

  def initialize(args = {})
    @solar_system = args['solar_system'] || args[:solar_system]
    @endpoint     = args['endpoint']     || args[:endpoint]
    @location     = args['location']     || args[:location]

    # TODO make variable
    @trigger_distance = 100

    # TODO would rather not access the cosmos registry directly here
    if @solar_system.is_a?(String)
      tsolar_system = Cosmos::Registry.instance.find_entity(:type => :solarsystem,
                                                            :name => @solar_system)
      @solar_system = tsolar_system unless tsolar_system.nil?
    end

    if @endpoint.is_a?(String)
      # XXX don't like doing this here
      tendpoint = Cosmos::Registry.instance.find_entity(:type => :solarsystem,
                                                        :name => @endpoint)
      @endpoint = tendpoint unless tendpoint.nil?
    end

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def valid?
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::SolarSystem)) &&
    (@endpoint.nil? || @endpoint.is_a?(Cosmos::SolarSystem))
    # && @solar_system.name != @endpoint.name
  end

  # does not accept any resources
  def accepts_resource?(res)
    false
  end

  def self.parent_type
    :solarsystem
  end

  def self.remotely_trackable?
    false
  end

  def parent
    @solar_system
  end

  def parent=(solar_system)
    @solar_system = solar_system
  end

  def has_children?
    false
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:trigger_distance => @trigger_distance,
         :solar_system     => (@solar_system.is_a?(String) ?
                               @solar_system : @solar_system.name),
         :endpoint         => (@endpoint.is_a?(String)     ?
                               @endpoint : @endpoint.name),
         :location         => @location}
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
