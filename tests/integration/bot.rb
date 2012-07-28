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
PASSWORD = ARGV.shift

RJR::Logger.log_level= ::Logger::INFO
login USER_NAME,  :password => PASSWORD

# A registry to track server side entities to prevent duplicates
class ClientRegistry
  include Singleton

  attr_reader :systems
  attr_reader :stations
  attr_reader :ships

  def initialize
    @systems = []
    @stations= []
    @ships   = []
  end

  def <<(value)
    if(value.is_a?(ClientSystem))
      @systems << value
    elsif(value.is_a?(ClientShip))
      @ships << value
    elsif(value.is_a?(ClientStation))
      @stations << value
    end
  end

  def include?(value)
    (!@systems.find { |s| s.server_system.name == value }.nil?) ||
    (!@ships.find   { |s| s.server_ship.id     == value }.nil?) ||
    (!@stations.find{ |s| s.server_station.id  == value }.nil?)
  end

  def [](index)
    @systems.find { |s| s.server_system.name == index } ||
    @ships.find   { |s| s.server_ship.id     == index } ||
    @stations.find{ |s| s.server_station.id  == index }
  end
end

# Client represetation of server solar system
class ClientSystem
  # name of the system
  attr_accessor :name

  # remote handle to system
  attr_accessor :server_system

  # resources in the system
  attr_accessor :resources

  # nearby systems ordered by proximity
  attr_accessor :nearby_systems

  def self.load(args = {})
    name = args[:name]
    if ClientRegistry.instance.include?(name)
      return ClientRegistry.instance[name]
    end
    return ClientSystem.new(args)
  end

  def initialize(args = {})
    @name = args[:name]
    ClientRegistry.instance << self
    refresh
  end

  def refresh
    @server_system = system(@name)
    nearby_system_names = @server_system.jump_gates.collect { |jg|
                                                     jg.endpoint }
    @nearby_systems = []
    nearby_system_names.each { |n|
      @nearby_systems << ClientSystem.load(:name => n)
    }
    @nearby_systems.sort! { |sys1, sys2|
      (@server_system.location - sys1.server_system.location) <=>
      (@server_system.location - sys2.server_system.location)
    }

    self
  end

  def refresh_resources
    @resources = @server_system.asteroids.collect { |ast|
                   resource_sources(ast)
                 }.flatten.delete_if { |rs| rs.nil? }
    @resources.each { |rs| rs.entity.solar_system = self }
  end
end

# Client representation of server station
class ClientStation
  # handle to the station as returned by the server
  attr_accessor :server_station

  # handle to the system its in
  attr_accessor :system

  def server_entity() @server_station end

  def self.load(args = {})
    name = args[:name]
    if ClientRegistry.instance.include?(name)
      return ClientRegistry.instance[name]
    end
    return ClientStation.new(args)
  end

  def initialize(args = {})
    @name   = args[:name]
    ClientRegistry.instance << self
    refresh
  end

  def refresh
    @server_station = station(@name)
    @system = ClientSystem.load(:name => @server_station.solar_system.name)
  end

  def move_to_system(system, &bl)
    @server_station.location.parent_id = system.server_system.location.id
    @station = @server_station
    move_to(@server_station.location)
    bl.call if bl
  end

  # registers and returns next system which to build station for
  def self.next_system(current_system)
    @@systems_lock ||= Mutex.new
    @@claimed_systems ||= []
    ns = nil

    @@systems_lock.synchronize {
      # determine if any linked system doesn't have a station
      # TODO sort systems placing those that have our ships and/or resources before those that don't
      current_system.server_system.jump_gates.each { |jg|
        sys = ClientRegistry.instance.systems.find { |sys| sys.server_system.name == jg.endpoint }
        se = system_entities(sys.server_system)
        unless se.find { |e| e.is_a?(Manufactured::Station) && e.user_id == USER_NAME } ||
                @@claimed_systems.include?(sys)
            # claim system so that other stations don't build
            @@claimed_systems << sys
            ns = sys
        end
      }
    }

    return ns
  end

  def construction_cycle
    @stop_construction = false
    @build_for_system = nil
    @construction_thread = Thread.new {
      until @stop_construction
        refresh

        # if we're building entities for a new system
        unless @build_for_system.nil?
          if @server_station.cargo_quantity >=
             (Manufactured::Ship.construction_cost(:frigate) + Manufactured::Station.construction_cost(:manufacturing))

            # construct the entities
            @station = @server_station
            new_station = construct_station :type => :manufacturing
            new_frigate = construct_ship    :type => :frigate

            # load them on the client side
            client_station = ClientStation.load(:name => new_station.id)
            client_frigate = FrigateShip.load(:name => new_frigate.id, :home_station => client_station)

            # move station / frigate to new system
            client_station.move_to_system(@build_for_system) do
              client_station.construction_cycle
            end
            client_frigate.move_to_system(@build_for_system) do
              ClientRegistry.instance.ships.select { |sh| sh.server_ship.type == :mining &&
                                                          sh.server_ship.parent.name == @build_for_system.server_system.name }.
                                            each {   |sh| sh.transfer_endpoint = client_frigate }
            end
            @build_for_system = nil
          end

        else
          @build_for_system = ClientStation.next_system(@system)

          # if we have enough resources, build miners and corvettes
          unless @build_for_system || 
                 @server_station.cargo_quantity <
                   (Manufactured::Ship.construction_cost(:mining) + Manufactured::Ship.construction_cost(:corvette))
            @station = @server_station
            new_miner    = construct_ship :type => :mining
            new_corvette = construct_ship :type => :corvette

            client_miner = MinerShip.load :name => new_miner.id
            client_corvette = CorvetteShip.load :name => new_corvette.id

            client_miner.mine_cycle()
            client_corvette.follow(client_miner).protect(client_miner)
          end
        end

        sleep 5
      end
    }

    return self
  end
end

# Client representation of server ship
class ClientShip
  # handle to the ship as returned by the server
  attr_accessor :server_ship
  
  def server_entity() @server_ship end

  # handle to the system its in
  attr_accessor :system

  def self.load(args = {})
    name = args[:name]
    if ClientRegistry.instance.include?(name)
      return ClientRegistry.instance[name]
    end
    return self.new(args)
  end


  def initialize(args = {})
    @name        = args[:name]
    ClientRegistry.instance << self
    refresh

    @system      = ClientSystem.load(:name => @server_ship.solar_system.name)
  end

  def refresh
    @server_ship = ship(@name)
  end

  def track_movement(distance, &bl)
    @@movement_callbacks_lock ||= Mutex.new
    @@movement_callbacks_lock.synchronize {
      @@movement_callbacks ||= {}
      @@movement_callbacks[@server_ship.id] ||= {}
      @@movement_callbacks[@server_ship.id][distance] ||= []
      @@movement_callbacks[@server_ship.id][distance] << bl
    }

    @ship = @server_ship
    subscribe_to :movement, :distance => 5  do |location|
      @server_ship.location = location

      callbacks_to_invoke = []
      @@movement_callbacks_lock.synchronize {
        new_callbacks = {}
        @@movement_callbacks[@server_ship.id].each { |dist,callbacks|
          ndist = dist - 5
          if ndist <= 0
            callbacks_to_invoke += callbacks
          else
            new_callbacks[ndist] = callbacks
          end
        }
        @@movement_callbacks[@server_ship.id] = new_callbacks
        nil
      }
      callbacks_to_invoke.each { |cb| cb.call }
    end
  end

  def follow_ship(ship)
    @following ||= false
    unless @following
      @ship = @server_ship
      follow ship.server_ship
      @following = true
    end

    ship.track_movement 10 do
      if ship.system.name != system.name
        move_to_system(ship.system) do
          @following = false
          follow_ship(ship)
        end
      else
        follow_ship(ship)
      end
    end
    return self
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
    nl = jumpgate.location + [10, 10, 10]
    move_to_location(nl)

    # on jumpgate arrival, trigger move to new system
    refresh
    track_movement(@server_ship.location - nl - 20) do
      RJR::Logger.info "ship #{@server_ship.id} arrived at jumpgate to #{jumpgate.endpoint}, triggering gate"
      nl.parent_id = system.server_system.location.id
      move_to_location(nl)
      @system = ClientSystem.load(:name => system.name)
      bl.call if bl
      nil
    end
  end
end

# Continously mine resources
class MinerShip < ClientShip

  # ship or station which miner will transfer resources to when at full cargo capacity
  attr_reader :transfer_endpoint
  def transfer_endpoint=(value)
    @transfer_endpoint = value
    unless @transfer_endpoint.nil?
      refresh
      if @server_ship.cargo_quantity >= @server_ship.cargo_capacity
        @transfer_endpoint.signal(self)
      end
    end
  end

  def initialize(args = {})
    @transfer_endpoint = args[:transfer_endpoint]

    super(args)
  end

  def nearest_nondepleted_resource
    res = nil
    systems = [@system]
    systems.each { |s|
      s.refresh_resources
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
    # get next resource to mine
    rs = nearest_nondepleted_resource

    # no more resource
    if rs.nil?
      RJR::Logger.info "no more resources in accessible systems, stopping movement/mining"
      return

    # next resource is in another system
    elsif rs.entity.location.parent_id != @system.server_system.location.id
      move_to_system(rs.entity.solar_system) do
        clear_callbacks
        RJR::Logger.info "ship #{@server_ship.id} arrived in system #{rs.entity.solar_system.name}, moving to next resource"
        @transfer_endpoint = ClientRegistry.instance.ships.find { |sh| sh.server_ship.type == :frigate &&
                                                                       sh.server_ship.parent.name == @system.server_system.name }
        mine_cycle()
      end

    # next resource is in this system
    else
      nl = rs.entity.location + [10, 10, 10]

      # mine if we are within mining distance
      if(@server_ship.location - nl) < @server_ship.mining_distance
        RJR::Logger.info "mining #{rs.entity} with #{@server_ship.id}"
        @ship = @server_ship
        # TODO retry for another resource if exception is raised
        start_mining rs
        subscribe_to :resource_collected do |s, srs, q|
          rs.quantity -= q
        end
        subscribe_to :mining_stopped do |cause, s, srs|
          if cause == "ship_cargo_full"
            @server_ship = s
            unless @transfer_endpoint.nil?
              @transfer_endpoint.signal(self) do
                @server_ship.resources.each { |rsid, quantity|
                  transfer_resource(@server_ship, @transfer_endpoint.server_entity, rsid, quantity)
                }
                mine_cycle()
              end
            end
          elsif cause == "resource_depleted"
            RJR::Logger.info "resource depleted"
            clear_callbacks
            rs.quantity = 0
            mine_cycle()
          end
        end

      # else move to resource
      else
        RJR::Logger.info "moving ship #{@server_ship.id} to #{rs.entity.name} to mine #{rs.resource.id}(#{rs.quantity})"
        move_to_location(nl)
        track_movement(@server_ship.location - nl - 20) do
          RJR::Logger.info "ship #{@server_ship.id} arrived at #{rs.entity.name}"
          mine_cycle()
        end
      end
    end

  end
end

# Follows and protects the specified ship
class CorvetteShip < ClientShip
  # ship we are attacking
  attr_accessor :attacking

  def initialize(args = {})
    @attacking = nil
    super(args)
  end

  def protect(ship)
    @stop_protect = false
    @protect_thread = Thread.new {
      until @stop_protect
        if @attacking.nil?
          refresh

          # attack enemy ships that come within specified proximity
          neighbors = nearby_locations(ship.server_ship.location, 50)
          neighbors.each { |loc|
            # XXX would prefer if there was some way to determine if
            # location corresponded to ship b4 issuing this call
            # FIXME surround w/ begin/rescue as many location's don't correspond to ships
            lship = ship(:location_id => loc.id)
            # TODO respect alliances
            unless lship.nil? ||
                   lship.user_id == USER_NAME ||
                   (@server_ship.location - lship.location) > @server_ship.attack_distance
              @attacking = lship
              @ship = @server_ship
              start_attacking(lship)
              subscribe_to :attacked do |attacker, defender|
              end
              subscribe_to :attacked_stop do |attacker, defender|
                @attacking = nil
              end

              break
            end
          }
        end
        sleep 5
      end
    }
    return self
  end
end

# Can be signaled to collect resources and deposit them at a station
class FrigateShip < ClientShip
  def initialize(args = {})
    @entities_to_visit  = []
    @entities_callbacks = []
    @entities_lock = Mutex.new

    @return_to_station = false
    @home_station = args[:home_station]
    super(args)
  end

  def transport_cycle
    refresh
    @return_to_station = (@server_ship.cargo_quantity > (0.75 * @server_ship.cargo_capacity))

    if @return_to_station
      nl = @home_station.server_station.location + [10, 10, 10]
      move_to_location(nl)
      track_movement(@server_ship.location - nl - 20) do
        dock(@server_ship, @home_station.server_station)
        @server_ship.resources.each { |rsid, quantity|
          transfer_resource(@server_ship, @home_station.server_station, rsid, quantity)
        }
        undock(@server_ship)
        @return_to_station = false
        transport_cycle
      end
      return
    end

    entity = nil
    cb     = nil
    @entities_lock.synchronize {
      entity = @entities_to_visit.shift
      cb     = @entities_callbacks.shift
    }
    unless entity.nil?
      nl = entity.server_entity.location + [10, 10, 10]
      move_to_location(nl)
      track_movement(@server_ship.location - nl - 20) do
        cb.call
        transport_cycle
      end
    end
  end

  # signal frigate should navigate to specified entity + invoke callback on arrival
  def signal(entity, &bl)
    @entities_lock.synchronize {
      @entities_to_visit  << entity
      @entities_callbacks << bl
    }
    transport_cycle unless @return_to_station

  end
end

listen

station = ClientStation.load :name => USER_NAME + "-manufacturing-station1"
station.construction_cycle()

frigate = FrigateShip.load :name => USER_NAME + "-frigate-ship1",
                           :home_station => station

miner = MinerShip.load :name   => USER_NAME + "-mining-ship1",
                       :transfer_endpoint => frigate
miner.mine_cycle()

corvette = CorvetteShip.load :name => USER_NAME + "-corvette-ship1"
corvette.follow_ship(miner).protect(miner)

Signal.trap("USR1") {
  stop
}

join
