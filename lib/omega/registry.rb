#!/usr/bin/ruby
# omega client registry, provides a safe way to monitor server entities
#   and subscribe to events / changes of state
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega

# Client side galaxy tracker.
class MonitoredGalaxy
  # [Cosmos::Galaxy] being tracked
  attr_accessor :server_galaxy

  def initialize(registry, server_galaxy)
    @registry = registry
    @server_galaxy = server_galaxy
  end

  # Return an array containing ordered list of systems with jump gates corresponding
  # to a path between from and to.
  #
  # TODO at some point factor in a shortest path algorthim
  def get_path(from, to)
    tree = @server_galaxy.solar_systems.collect { |s|
             [s.name, s.jump_gates.collect { |jg| jg.endpoint }]
           }

    n = tree.find { |n| n.first == from }
    return nil if n.nil?
    n.last.each { |r|
      return [from, r] if r == to
      p = get_path(r, to) 
      return [from] + p unless p.nil?
    }
    return nil
  end

  def refresh
    #puts "Refreshing galaxy #{self.name}"
    #self.solar_systems.each { |sys|
    #  sys.planets.each { |planet|
    #    @registry.track_location(planet.location.id, 5)
    #  }
    #  sys.asteroids.each { |ast|
    #    ast.solar_system = sys
        #@registry.node.invoke_request('omega-queue', 'cosmos::get_resources', ...)
    #  }
    #}
  end

  def method_missing(meth, *args, &block)
    @server_galaxy.send meth, *args, &block
  end
end

# Client side ship tracker.
class MonitoredShip

  # [Manufactured::Ship] being tracked
  attr_accessor :server_ship
  attr_accessor :move_to_location
  attr_accessor :move_to_system

  attr_accessor :moving
  attr_accessor :mining
  attr_accessor :attacking

  def initialize(registry, server_ship)
    @registry = registry
    @server_ship = server_ship

    @move_to_location = nil
    @move_to_system = nil
    @move_to_gate   = nil
    @gates_path = []

    @moving = false
    @following = false
    @mining = false
    @attacking = nil

    @registry.track_location(server_ship.location.id, 5)
  end

  def galaxy
    @registry.galaxies.find { |id,g|
      g.solar_systems.collect { |s|s.name }.include?(self.solar_system.name)
   }.last
  end

  def refresh
    @moving    = !@server_ship.location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped)
    @following =  @server_ship.location.movement_strategy.is_a?(Motel::MovementStrategies::Follow)
    @mining    = !@server_ship.mining.nil?
    # TODO set @attacking
  end

  def sync
    if @move_to_location
      if (self.location - @move_to_location) < 10
        puts "Ship #{self.server_ship} arrived at #{@move_to_location}"
        @moving = false
        @move_to_location = nil

      else
        if !@moving
          puts "Ship #{self.id} moving to location #{@move_to_location}"
          @moving = true
          @registry.node.invoke_request 'omega-queue', 'manufactured::move_entity',
                                         self.id, @move_to_location
          @server_ship = @registry.node.invoke_request 'omega-queue', 'manufactured::get_entity',
                                                       'with_id', self.id
        end
        return true

      end

    # move to jump gates along path
    elsif !@move_to_gate.nil? || @gates_path.size > 0
      @move_to_gate = @gates_path.shift if @move_to_gate.nil?
      if (self.location - @move_to_gate.location) > @move_to_gate.trigger_distance
        puts "Ship #{self.id} moving to jump gate #{@move_to_gate}"
        @move_to_location = @move_to_gate.location + [10, 10, 10]
        #return self.sync
      else
        dsys = self.galaxy.solar_systems.find { |s| s.name == @move_to_gate.endpoint }
        puts "Ship #{self.id} moving to system #{dsys.name}"
        self.location.parent_id = dsys.location.id
        @registry.node.invoke_request 'omega-queue', 'manufactured::move_entity',
                                       self.id, self.location
        @server_ship = @registry.node.invoke_request 'omega-queue', 'manufactured::get_entity',
                                                     'with_id', self.id
        @move_to_gate = nil
      end


    elsif @move_to_system
      if self.solar_system.name == @move_to_system.name
        @move_to_system = nil
      else
        path = self.galaxy.get_path(self.solar_system.name, @move_to_system.name)
        if path.nil?
          puts "Ship #{self.id} cannot find path from #{self.solar_system.name} to #{@move_to_system.name}"
        else
          @gates_path = []
          1.upto(path.size-1) { |i|
            sys = self.galaxy.solar_systems.find { |s| s.name == path[i-1] }
            gate = sys.jump_gates.find { |jg| jg.endpoint == path[i] }
            @gates_path << gate
          }
        end
      end

    end

    return false
  end

  def on_event(event, *args)
    case event
    when 'mining_stopped' then
      puts "Ship #{self.id} mining stopped"
      @mining = false

    when 'attacked_stop' then
      puts "Ship #{self.id} attacked stop"
      @attacking = nil

    end
  end

  def method_missing(meth, *args, &block)
    @server_ship.send meth, *args, &block
  end
end

# Client side station tracker
class MonitoredStation
  # [Manufactured::Station] being tracked
  attr_accessor :server_station
  attr_accessor :move_to_system

  def initialize(registry, server_station)
    @registry = registry
    @server_station = server_station
    @move_to_system = nil
  end

  def sync
    if @move_to_system
      self.location.parent_id = @move_to_system.location.id
      @registry.node.invoke_request 'omega-queue', 'manufactured::move_entity',
                                     self.id, self.location
      @move_to_system = nil
    end
    return false
  end

  def method_missing(meth, *args, &block)
    @server_station.send meth, *args, &block
  end
end

# Client side user tracker
#
# Contains handles to monitored ships and statiohs owned by the user.
class MonitoredUser

  # [Users::User] being tracked
  attr_accessor :server_user
  attr_accessor :ships
  attr_accessor :stations

  SYSTEM_USERS = ['users', 'cosmos', 'manufactured', 'admin', 'rlm', 'rcm']

  def initialize(registry, server_user)
    @registry = registry
    @server_user = server_user
    @ships    = {}
    @stations = {}
  end

  def <<(entity)
    if entity.is_a?(MonitoredShip)
      @ships[entity.id] ||= entity
      @ships[entity.id].server_ship = entity.server_ship

    elsif entity.is_a?(MonitoredStation)
      @stations[entity.id] ||= entity
      @stations[entity.id].server_station = entity.server_station
    end
  end

  def refresh
    user_ships = @registry.node.invoke_request('omega-queue', 'manufactured::get_entities',
                                               'of_type',     'Manufactured::Ship',
                                               'owned_by',     self.id)
    user_stats = @registry.node.invoke_request('omega-queue', 'manufactured::get_entities',
                                               'of_type',     'Manufactured::Station',
                                               'owned_by',     self.id)

    user_ships.each { |sh|
      self << MonitoredShip.new(@registry, sh)
      @ships[sh.id].refresh
    }

    user_stats.each { |st|
      self << MonitoredStation.new(@registry, st)
    }

    # remove ships no longer present
    ships_to_delete = []
    @ships.each { |id,sh|
      if !user_ships.collect { |us| us.id }.include?(id)
        puts "Ship #{id} no longer, present, deleting"
        ships_to_delete << id
      end
    }
    ships_to_delete.each { |id| @ships.delete(id) }

    # remove stations no longer present
    stations_to_delete = []
    @stations.each { |id,st|
      if user_stats.find { |us| us.id == id }.nil?
        puts "Station #{id} no longer, present, deleting"
        stations_to_delete << id
      end
    }
    stations_to_delete.each { |id| @stations.delete(id) }
  end

  def method_missing(meth, *args, &block)
    @server_user.send meth, *args, &block
  end

end

# Client side registry of monitored galaxies and users
class MonitoredRegistry
  attr_accessor :node
  attr_accessor :registry_lock
  attr_accessor :output

  attr_accessor :galaxies
  attr_accessor :users
  attr_accessor :systems_graph

  def initialize(node, output=nil)
    @node = node
    @galaxies = {}
    @users    = {}
    @tracked_locations = []

    @registry_lock = Mutex.new

    if output
      @output   = output
      @output.registry = self
    end

    register_handlers
  end

  def register_handlers
    registry = self
    RJR::Dispatcher.add_handler('motel::on_movement') { |location|
      registry.registry_lock.synchronize{
        #puts "Location #{location.id} movement callback invoked"
        entity = nil
        registry.users.each { |id,u|
          u.ships.each { |id,sh|
            if sh.location.id == location.id
              entity = sh
              break
            end
          }
          break unless entity.nil?

          u.stations.each { |id,st|
            if st.location.id == location.id
              entity = st
              break
            end
          }
          break unless entity.nil?
        }

        registry.galaxies.each { |id,g|
          g.solar_systems.each { |sys|
            sys.planets.each { |pln|
              if pln.location.id == location.id
                entity = pln
                break
              end
            }
            break unless entity.nil?
          }
          break unless entity.nil?
        } if entity.nil?

        unless entity.nil?
          entity.location = location
          registry.output.refresh(entity) if registry.output
        end
      }
      nil
    }
    RJR::Dispatcher.add_handler('manufactured::event_occurred') { |*args|
      registry.registry_lock.synchronize{
        event  = args.shift
        reason = (event == 'mining_stopped' ? args.shift : nil)
        sentity = args.shift
        puts "Manufactured entity #{sentity} raised event #{event}/#{reason}"
        registry.users.each { |uid,u|
          rentity = u.ships.find { |sid,sh| sh.id == sentity.id }
          unless rentity.nil?
            rentity = rentity.last
            rentity.server_ship = sentity
            rentity.on_event event, *args
            registry.output.refresh(rentity) if registry.output
            break
          end
        }
      }
      nil
    }
  end

  def resources_for(entity)
    if entity.is_a?(Cosmos::SolarSystem)
      return entity.asteroids.collect { |ast|
        ress = @node.invoke_request 'omega-queue', 'cosmos::get_resource_sources', ast.name
        ress.each{ |res| res.entity.solar_system = entity }
        ress
      }.flatten
    end
    return []
  end

  def track_location(location_id, distance)
    return if @tracked_locations.include?(location_id)

    @tracked_locations << location_id
    @node.invoke_request('omega-queue', 'motel::track_movement', location_id, distance)
  end

  def <<(entity)
    if entity.is_a?(MonitoredUser)
      @users[entity.id] ||= entity
      @users[entity.id].server_user = entity.server_user

    elsif entity.is_a?(MonitoredGalaxy)
      @galaxies[entity.name] ||= entity
      @galaxies[entity.name].server_galaxy = entity.server_galaxy
    end
  end

  def refresh
    # TODO this lock will be held during calls to node.invoke_request, possibly hurting performance
    @registry_lock.synchronize{
      server_users    = @node.invoke_request('omega-queue', 'users::get_entities', 'of_type', 'Users::User')

      # only load these once
      server_galaxies = @galaxies.empty? ? @node.invoke_request('omega-queue', 'cosmos::get_entities', 'of_type', 'galaxy') : []

      server_users.each { |u|
        mu = MonitoredUser.new(self, u)
        self << mu
        @users[mu.id].refresh
      }

      server_galaxies.each { |g|
        mg = MonitoredGalaxy.new(self, g)
        self << mg
        @galaxies[mg.name].refresh
      }

      @output.refresh if @output
    }
  end

  def start
    @terminate = false
    @run_thread = Thread.new {
      until @terminate
        refresh
        sleep 3 # TODO make refresh poll cycle delay variable or subscribe to new entity creation when that functionality is available
      end
    }
    return self
  end

  def stop
    puts "Terminating run cycle..."
    @terminate = true
    @output.stop.close
    return self
  end

  def join
    @run_thread.join
    return self
  end
end

end # module Omega
