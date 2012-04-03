# Manufactured entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'singleton'

module Manufactured

class Registry
  include Singleton

  # entities we are tracking
  # TODO manually define these accessors, protecting arrays w/ the entities_lock
  attr_reader :ships
  attr_reader :stations
  attr_reader :fleets

  # attack commands client has issued to be regularily run
  attr_reader :attack_commands

  # mining commands client has issued to be regularily run
  attr_reader :mining_commands

  ATTACK_POLL_DELAY = 0.5 # TODO make configurable?
  MINING_POLL_DELAY = 0.5 # TODO make configurable?

  def initialize
    init
  end

  def init
    terminate

    @ships    = []
    @stations = []
    @fleets   = []
    @attack_commands = []
    @mining_commands = []

    terminate
    @terminate_cycles = false
    @entities_lock = Mutex.new
    @attack_thread = Thread.new { attack_cycle }
    @mining_thread = Thread.new { mining_cycle }
  end

  def running?
    !@terminate_cycles && !@attack_thread.nil? && !@mining_thread.nil? &&
    (@attack_thread.status == 'run' || @attack_thread.status == 'sleep') &&
    (@mining_thread.status == 'run' || @mining_thread.status == 'sleep')
  end

  def terminate
    @terminate_cycles = true

    @attack_thread.join unless @attack_thread.nil?
    @mining_thread.join unless @mining_thread.nil?
  end

  def find(args = {})
    id        = args[:id]
    parent_id = args[:parent_id]
    user_id   = args[:user_id]
    type      = args[:type]
    location_id = args[:location_id]

    entities = []

    children.each { |entity|
      entities << entity if (id.nil?        || entity.id         == id)        &&
                            (parent_id.nil? || (entity.parent && (entity.parent.name  == parent_id))) &&  # FIXME fleet parent could be nil (autodelete fleet if no ships?)
                            (user_id.nil?   || entity.user_id    == user_id)   &&
                            (location_id.nil? || (entity.location && entity.location.id == location_id)) &&
                            (type.nil?      || entity.class.to_s == type)

    }
    entities
  end

  def children
    children = []
    @entities_lock.synchronize{
      children = @ships + @stations + @fleets
    }
    children
  end

  def create(entity)
    @entities_lock.synchronize{
      if entity.is_a?(Manufactured::Ship)
        @ships << entity  unless @ships.include?(entity)
      elsif entity.is_a?(Manufactured::Station)
        @stations << entity unless @stations.include?(entity)
      elsif entity.is_a?(Manufactured::Fleet)
        @fleets << entity unless @fleets.include?(entity)
      end
    }
  end

  # add new attack command to run
  def schedule_attack(args = {})
    @entities_lock.synchronize{
      @attack_commands << AttackCommand.new(args)
    }
  end

  # add new mining command to run
  def schedule_mining(args = {})
    @entities_lock.synchronize{
      @mining_commands << MiningCommand.new(args)
    }
  end

  # invoked in thread to periodically invoke attack commands
  def attack_cycle
    until @terminate_cycles
      @entities_lock.synchronize{
        # run attack if appropriate
        @attack_commands.each { |ac|
          ac.attack! if ac.attackable?
        }

        # remove attack commands no longer necessary
        @attack_commands.reject! { |ac| ac.remove? }

        # remove ships w/ <= 0 hp
        @ships.reject! { |sh| sh.hp <= 0 }
      }

      sleep ATTACK_POLL_DELAY
    end
  end

  # invoked in thread to periodically invoke mining commands
  def mining_cycle
    until @terminate_cycles
      @entities_lock.synchronize{
        # run mining operation if appropriate
        @mining_commands.each { |mc|
          if mc.minable?
            mc.ship.start_mining(mc.resource_source) unless mc.ship.mining?
            mc.mine!
          end
        }

        # remove mining commands no longer necessary
        to_remove = @mining_commands.select { |mc| mc.remove? }
        to_remove.each { |mc|
          mc.ship.stop_mining
          @mining_commands.delete(mc)
        }

        # TODO remove resource sources w/ quantity <= 0 ?
      }

      sleep MINING_POLL_DELAY
    end
  end

  # Save state of the registry to specified stream
  def save_state(io)
    children.each { |entity| 
      unless entity.is_a?(Manufactured::Fleet)
        io.write entity.to_json + "\n"
      end
    }
  end

  # restore state of the registry from the specified stream
  def restore_state(io)
    io.each { |json|
      entity = JSON.parse(json)
      if entity.is_a?(Manufactured::Ship) || entity.is_a?(Manufactured::Station)
        create(entity)
      end
    }
  end


end

end
