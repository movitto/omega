#!/usr/bin/ruby
# single integration test bot (rev 2)
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'

USER_NAME = ARGV.shift
PASSWORD = ARGV.shift

bot_id = "bot-#{Motel.gen_uuid}"

# Client representation of server station
class ManufacturingStation
  attr_accessor :station

  def initialize(registry, station)
    @registry = registry
    @station  = station
    @built_for_system = nil
  end

  def sync
    return true if @station.sync

    # needs to be here to set system on new entities post refresh
    # TODO would rather figure out a better way as this will not be available if bot is terminted / restarted
    #   (perhaps just run the invoke_requests to move locations manually after constructing below)
    if @built_for_system
      station_built = @registry.output.current_user.stations.find { |id,st| st.id == @station_built }.last
      ship_built    = @registry.output.current_user.ships.find { |id,sh| sh.id == @ship_built }.last
      station_built.move_to_system = @built_for_system
      ship_built.move_to_system    = @built_for_system
      @built_for_system = nil
    end

    # construct entities for new systems first
    if @registry.output.pending_systems.size > 0
      if self.cargo_quantity >=
         (Manufactured::Ship.construction_cost(:frigate) + Manufactured::Station.construction_cost(:manufacturing))
        @built_for_system = @registry.output.pending_systems.shift
        @station_built    = "#{USER_NAME}-manufacturing-station#{@registry.output.next_id}"
        @ship_built       = "#{USER_NAME}-frigate-ship#{@registry.output.next_id}"

        puts "ManufacturingStation #{self.id} constructing station(#{@station_built})/frigate(#{@ship_built}) for #{@built_for_system}"

        begin
          @registry.node.invoke_request 'omega-queue',
                                        'manufactured::construct_entity',
                                         self.id, 'Manufactured::Station',
                                        'type', 'manufacturing',
                                        'id', @station_built 
          @registry.node.invoke_request 'omega-queue',
                                        'manufactured::construct_entity',
                                         self.id, 'Manufactured::Ship',
                                        'type', 'frigate',
                                        'id', @ship_built
        rescue Exception => e
          puts "ManufacturingStation #{self.id} had problem constructing station(#{@station_built})/frigate(#{@ship_built}) for #{@built_for_system}: #{e}"
        end


        return false
      end

      return true

    # if no pending systems, construct additional miners / corvettes
    else
      if self.cargo_quantity >=
         (Manufactured::Ship.construction_cost(:mining) + Manufactured::Ship.construction_cost(:corvette))
        begin
          ship1_id = @registry.output.next_id
          ship2_id = @registry.output.next_id

          # construct
          @registry.node.invoke_request 'omega-queue',
                                        'manufactured::construct_entity',
                                         self.id, 'Manufactured::Ship',
                                        'type', 'mining',
                                        'id', "#{USER_NAME}-mining-ship#{ship1_id}"
          @registry.node.invoke_request 'omega-queue',
                                        'manufactured::construct_entity',
                                         self.id, 'Manufactured::Ship',
                                        'type', 'corvette',
                                        'id', "#{USER_NAME}-corvette-ship#{ship2_id}"
  
        rescue Exception => e
          puts "ManufacturingStation #{self.id} had problem constructing miner(#{ship1_id})/corvette(#{ship2_id}): #{e}"
        end
      end
    end

    return false

  end

  def method_missing(meth, *args, &block)
    @station.send meth, *args, &block
  end
end

# Continously mine resources
class MiningShip
  attr_accessor :ship
  attr_accessor :protector

  def initialize(registry, ship)
    @registry = registry
    @ship = ship
  end

  def nearest_nondepleted_resource
    res = nil
    systems = [self.solar_system]
    systems.each { |sys|
      res = @registry.resources_for(sys).select { |sr| sr.quantity > 0 }.
                        sort { |a,b| (self.location - a.entity.location) <=>
                                     (self.location - b.entity.location) }.first
      if res.nil?
        adj_systems = sys.jump_gates.collect { |jg|
          @registry.galaxies.collect { |name,g|
            g.solar_systems.find { |s| s.name == jg.endpoint }
          }.first }
        adj_systems.each { |as| systems << as unless systems.include?(as) }
        
      else
        break
      end
    }
    res
  end

  def sync
    return true if @ship.sync || self.mining

    # cargo capacity full
    if (self.cargo_quantity + self.mining_quantity) >= self.cargo_capacity
      puts "Ship #{self.id} capacity full"
      frigate = @registry.output.frigates.find { |id,f| f.solar_system.name == self.solar_system.name }
      unless frigate.nil?
        frigate = frigate.last
        puts "Miner #{self.id} signaling frigate #{frigate.id}"
        frigate.signal(self){ |ms|
          puts "Frigate #{frigate.id} arrived at #{ms.id}"
          frigate.transfer_resources
          frigate.move_to_station { |station|
            puts "Frigate arrived at station #{station.id}"
            frigate.transfer_resources
          }
        }
      end
      return true
    end

    res = nearest_nondepleted_resource

    # no more resources
    if res.nil?
      puts "no more resources in accessible systems, stopping movement/mining"
      return false

    # resource is in a different system
    elsif res.entity.location.parent_id != self.solar_system.location.id
      puts "Miner #{self.id} in different system than resource in system #{res.entity.solar_system}, moving"
      self.move_to_system = res.entity.solar_system
      self.sync

    # resource is too far away to mine
    elsif (self.location - res.entity.location) > self.mining_distance
      self.move_to_location = res.entity.location + [10, 10, 10]
      puts "Miner #{self.id} too far away from resource #{res.id}, moving to #{self.move_to_location}"
      self.sync
    

    # start mining
    else
      puts "Miner #{self.id} starting to mine #{res.id}"
      begin
        @registry.node.invoke_request 'omega-queue', 'manufactured::subscribe_to',
                                      self.id, 'mining_stopped'

        @registry.node.invoke_request 'omega-queue', 'manufactured::start_mining',
                                      self.id, res.entity.name, res.resource.id
        self.mining = true
      rescue Exception => e
        puts "Miner #{self.id} had problem mining #{res.entity.name}/#{res.resource.id}: #{e}"
      end
    end

    return true
  end

  def method_missing(meth, *args, &block)
    @ship.send meth, *args, &block
  end
end

# Follows and protects the specified ship
class CorvetteShip
  attr_accessor :ship
  attr_accessor :protecting

  def initialize(registry, ship)
    @registry = registry
    @ship = ship
  end

  def sync
    return true if @ship.sync

    # pick first miner that isn't being protected
    if @protecting.nil?
      @protecting = @registry.output.miners.find { |id,sh| sh.protector.nil? }
      return false if @protecting.nil?
      @protecting = @protecting.last
      @protecting.protector = self
      puts "Corvette #{self.id} protecting miner #{@protecting.id}"
    end

    if self.solar_system.name != @protecting.solar_system.name
      puts "Corvette #{self.id} in different system than miner, moving to #{@protecting.solar_system.name}"
      @following = false
      self.move_to_system = @protecting.solar_system
      return self.sync
    end

    unless @following
      puts "Corvette #{self.id} following miner"
      begin
        @registry.node.invoke_request 'omega-queue', 'manufactured::follow_entity', self.id, @protecting.id, 10
        @following = true
      rescue Exception => e
        puts "Corvette #{self.id} had error following #{@protecting.id}: #{e}"
      end
    end

    return true unless self.attacking.nil?

    neighbors = @registry.node.invoke_request 'omega-queue', 'motel::get_locations', 'within', self.attack_distance, 'of', self.location
    neighbors.each { |loc|
      begin
        sh = @registry.node.invoke_request 'omega-queue', 'manufactured::get_entity', 'of_type', 'Manufactured::Ship', 'with_location', loc.id
        # TODO respect alliances
        unless sh.nil? || sh.user_id == USER_NAME
          puts "Corvette #{self.id} detected enemy #{sh.id} in vicinity of #{@protecting.location}, attacking"
          @registry.node.invoke_request 'omega-queue', 'manufactured::subscribe_to',
                                         self.id, 'attacked_stop'
          @registry.node.invoke_request 'omega-queue', 'manufactured::attack_entity',
                                         self.id, sh.id
          self.attacking = sh
          break
        end

      rescue Exception => e
        unless e.to_s =~ /manufactured entity specified by.*not found/
          puts "Corvette #{self.id}: exception when starting attack - #{e}"
        end
      end
    }

    return !self.attacking.nil?
  end

  def method_missing(meth, *args, &block)
    @ship.send meth, *args, &block
  end
end

# Can be signaled to collect resources and deposit them at a station
class FrigateShip
  attr_accessor :ship
  attr_accessor :visiting
  attr_accessor :entities_to_visit

  def transfer_from
    return nil if @visiting.nil? || @ship.nil?
    return @visiting.is_a?(Omega::MonitoredStation) ? @ship : @visiting
  end

  def transfer_to
    return nil if @visiting.nil? || @ship.nil?
    return @visiting.is_a?(Omega::MonitoredStation) ? @visiting : @ship
  end

  def initialize(registry, ship)
    @registry = registry
    @ship = ship

    @visiting = nil
    @entities_to_visit = []

    self.move_to_station if self.resources.size > 0
  end

  def signal(target, &bl)
    if !@visiting.nil? && @visiting.id == target.id
      @arrival_callback = bl
      return
    end

    entity = @entities_to_visit.find { |e| e.first.id == target.id }
    if entity.nil?
      @entities_to_visit << [target, bl]
    else
      entity[1] = bl
    end
  end

  def flag(target, &bl)
    @entities_to_visit.delete_if { |e| e.first == target }
    @entities_to_visit.unshift [target, bl]
  end

  def move_to_station(&bl)
    station = @registry.output.current_user.stations.find { |id,st| st.solar_system.name == self.solar_system.name }.last
    self.flag station, &bl 
  end

  def transfer_resources
    if !@visiting.nil? &&
       ((self.location - @visiting.location) <= transfer_from.transfer_distance)
      puts "Transferring resources from #{transfer_from.id} to #{transfer_to.id}"
      begin
        transfer_from.resources.each { |rsid, quantity|
          @registry.node.invoke_request 'omega-queue','manufactured::transfer_resource',
                                         transfer_from.id, transfer_to.id, rsid, quantity
        }
        #transfer_from.update
        #transfer_to.update
        #@visiting = nil
      rescue Exception => e
        puts "Frigate #{self.id}: problem transferring resources #{transfer_to.id}->#{transfer_from.id}: #{e}"
      end
    end
  end

  def sync
    return true if @ship.sync

    if !@visiting.nil?
      return true if ((self.location - @visiting.location) > transfer_from.transfer_distance)

      # invoke arrival callback
      @arrival_callback.call @visiting
    end

    @visiting, @arrival_callback = *(@entities_to_visit.shift)
    return false if @visiting.nil?
    puts "Frigate moving to #{@visiting.id}"

    self.move_to_location = @visiting.location + [10, 10, 10]
    self.sync
  end

  def method_missing(meth, *args, &block)
    @ship.send meth, *args, &block
  end
end

# handle server updates
class BotOutput
  attr_accessor :registry

  attr_accessor :frigates
  attr_accessor :corvettes
  attr_accessor :miners
  attr_accessor :manufacturing_stations

  attr_accessor :current_user

  # systems which user does not have stations in
  attr_accessor :pending_systems

  def initialize
    @frigates  = {}
    @corvettes = {}
    @miners    = {}
    @manufacturing_stations = {}
  end

  def next_id
    @counter ||= [@frigates.size, @corvettes.size, @miners.size, @manufacturing_stations.size].sort.last
    @counter += 1
  end

  def refresh(invalidated = nil)
    # doing a general / overall refresh
    if invalidated.nil?

      # find user in registry
      @current_user = @registry.users.find { |id,u| id == USER_NAME }.last

      # find systems which user has stations in
      station_systems =
        @registry.galaxies.collect { |name,g|
          g.solar_systems.select { |sys|
            ! current_user.stations.find { |id,st|
              st.solar_system.name == sys.name }.nil?
          }
        }.flatten

      # find adjancent systems with no stations
      @pending_systems = []
      station_systems.each { |sys|
        sys.jump_gates.each { |jg|
          @registry.galaxies.each { |name,g|
            esys = g.solar_systems.find { |sys| sys.name == jg.endpoint }
            if esys && current_user.stations.find { |id,st|
               st.solar_system.name == esys.name }.nil?
                @pending_systems << esys
            end
          }
        }
      }
    end

    # update registered stations / ships (TODO run sync operation after all the update operations)
    @current_user.stations.each { |id,st|
      if invalidated.nil? || (invalidated.is_a?(Omega::MonitoredStation) && st.id == invalidated.id)
        if st.id =~ /#{USER_NAME}-manufacturing-station.*/
          @manufacturing_stations[st.id] ||= ManufacturingStation.new(@registry, st)
          @manufacturing_stations[st.id].station = invalidated unless invalidated.nil?
          @manufacturing_stations[st.id].sync
        end
      end
    }
    @current_user.ships.each { |id,sh|
      if invalidated.nil? || (invalidated.is_a?(Omega::MonitoredShip) && sh.id == invalidated.id)
        if sh.id =~ /#{USER_NAME}-frigate-ship.*/
          @frigates[sh.id] ||= FrigateShip.new(@registry, sh)
          @frigates[sh.id].ship = invalidated unless invalidated.nil?
          @frigates[sh.id].sync

        elsif sh.id =~ /#{USER_NAME}-mining-ship.*/
          @miners[sh.id] ||= MiningShip.new(@registry, sh)
          @miners[sh.id].ship = (invalidated.nil? ? sh : invalidated)
          @miners[sh.id].sync

        elsif sh.id =~ /#{USER_NAME}-corvette-ship.*/
          @corvettes[sh.id] ||= CorvetteShip.new(@registry, sh)
          @corvettes[sh.id].ship = (invalidated.nil? ? sh : invalidated)
          @corvettes[sh.id].sync

        end
      end
    }
  end
  
  def stop
    return self
  end

  def close
    return self
  end
end


#RJR::Logger.log_level= ::Logger::INFO

node = RJR::AMQPNode.new :broker => 'localhost', :node_id => bot_id

user = Users::User.new :id => USER_NAME, :password => PASSWORD
session = node.invoke_request 'omega-queue', 'users::login', user
node.message_headers['session_id'] = session.id

output = BotOutput.new
Omega::MonitoredRegistry.new(node, output).start.join
