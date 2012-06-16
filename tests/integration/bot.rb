#!/usr/bin/ruby
# single integration test bot
#
# give bot a station and a couple of ships in the specified system
# and instructions on how to build up from there
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'
require 'singleton'

include Omega::DSL

USER_NAME = ARGV.shift

RJR::Logger.log_level= ::Logger::INFO
login 'admin',  :password => 'nimda'

class ClientRegistry
  include Singleton

  def initialize
    @systems = []
    @ships   = []
  end

  def <<(value)
    if(value.is_a?(ClientSystem))
      @systems << value
    elsif(value.is_a?(ClientShip))
      @ships << value
    end
  end

  def include?(value)
    (!@systems.find { |s| s.name == value }.nil?) ||
    (!@ships.find   { |s| s.id   == value }.nil?)
  end

  def [](index)
    @systems.find { |s| s.name == value } ||
    @ships.find   { |s| s.id   == value }
  end
end

class ClientSystem
  # name of the system
  attr_accessor :name

  # remote handle to system
  attr_accessor :server_system

  # resources in the system
  attr_accessor :resources

  # nearby systems ordered by proximity
  attr_accessor :nearby_systems

  def self.load_or_create(name)
    if ClientRegistry.instance.include?(name)
      return ClientRegistry.instance[name]
    end
    return ClientSystem.new(:name => name)
  end

  def initialize(args = {})
    @name = args[:name]
    ClientRegistry.instance << self
    refresh
  end

  def refresh
    @server_system = system(@name)
    @resources = @server_system.asteroids.collect { |ast|
                          resource_sources(ast) }.flatten
    @resources.each { |rs| rs.entity.solar_system = self }

    nearby_system_names = @server_system.jump_gates.collect { |jg|
                                                     jg.endpoint }
    @nearby_systems = []
    nearby_system_names.each { |n|
      @nearby_systems << ClientSystem.load_or_create(n)
    }
    @nearby_systems.sort! { |sys1, sys2|
      (@server_system.location - sys1.server_system.location) <=>
      (@server_system.location - sys2.server_system.location)
    }

    self
  end
end

class ClientShip
  # handle to the ship as returned by the server
  attr_accessor :server_ship

  # handle to the system its in
  attr_accessor :system

  def initialize(args = {})
    @name        = args[:name]
    refresh

    @system      = ClientSystem.new(:name => @server_ship.solar_system.name)
  end

  def refresh
    @server_ship = ship(@name)
  end

  def track_movement(distance, &bl)
    @movement_callbacks_lock ||= Mutex.new
    @movement_callbacks_lock.synchronize {
      @movement_callbacks ||= {}
      @movement_callbacks[distance] ||= []
      @movement_callbacks[distance] << bl
    }

    subscribe_to :movement, :distance => 5  do |location|
      @server_ship.location = location

      callbacks_to_invoke = []
      @movement_callbacks_lock.synchronize {
        new_callbacks = {}
        @movement_callbacks.each { |dist,callbacks|
          ndist = dist - 5
          if ndist <= 0
            callbacks_to_invoke += callbacks
          else
            new_callbacks[ndist] = callbacks
          end
        }
        @movement_callbacks = new_callbacks
        nil
      }
      callbacks_to_invoke.each { |cb| cb.call }
    end
  end

  def move_to_location(new_location)
    @ship = @server_ship
    move_to(new_location)
  end

  def move_to_system(system, &bl)
    # TODO support mapping multi-system route

    # move to jumpgate to specified system
    jumpgate = @system.server_system.jump_gates.find { |jg|
                        jg.endpoint == system.name }
puts "JG #{system}/#{system.server_system.location}"
    nl = jumpgate.location + [10, 10, 10]
    move_to_location(nl)

    # on jumpgate arrival, trigger move to new system
    track_movement(@server_ship.location - nl - 20) do
      RJR::Logger.info "ship #{@server_ship.id} arrived at jumpgate to #{jumpgate.endpoint}, triggering gate"
puts "JGT #{system}/#{system.server_system.location}"
      nl.parent_id = system.server_system.location.id
      move_to_location(nl)
      @system = system
      bl.call if bl
    end
  end
end

class MinerShip < ClientShip

  def nearest_nondepleted_resource
    res = nil
    systems = [@system]
    systems.each { |s|
      res = s.resources.select { |sr| sr.quantity > 0 }.
                        sort { |a,b| (@server_ship.location - a.entity.location) <=>
                                     (@server_ship.location - b.entity.location) }.first
      if res.nil?
        s.nearby_systems.each { |ns|
          systems << ns unless systems.include?(ns)
        }
      else
        break
      end
    }
    res
  end

  def mine_cycle()
    rs = nearest_nondepleted_resource
    if rs.nil?
      RJR::Logger.info "no more resources in accessible systems, stopping movement/mining"
      return
    elsif rs.entity.location.parent_id != @system.server_system.location.id
      move_to_system(rs.entity.solar_system) do
        clear_callbacks
        RJR::Logger.info "ship #{@server_ship.id} arrived in system #{rs.entity.solar_system.name}, moving to next resource"
        mine_cycle()
      end
    else
      RJR::Logger.info "moving ship #{@server_ship.id} to #{rs.entity.name} to mine #{rs.resource.id}(#{rs.quantity})"
      nl = rs.entity.location + [10, 10, 10]
      move_to_location(nl)
      track_movement(@server_ship.location - nl - 20) do
        RJR::Logger.info "ship #{@server_ship.id} arrived at #{rs.entity.name}, starting to mine"
        @ship = @server_ship
        start_mining rs
        subscribe_to :resource_collected do |s, srs, q|
          rs.quantity -= q
        end
        subscribe_to :resource_depleted do |s,srs|
          RJR::Logger.info "resource depleted"
          clear_callbacks
          rs.quantity = 0
          mine_cycle()
        end
      end
    end

  end
end

class Corvette < ClientShip
end

miner = MinerShip.new :name   => USER_NAME + "-mining-ship1"
miner.mine_cycle()

Signal.trap("USR1") {
  stop
}

listen
join
