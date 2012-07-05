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
    @attack_commands = {}
    @mining_commands = {}

    terminate
    @terminate_cycles = false
    @entities_lock = Mutex.new
    @attack_thread = Thread.new { attack_cycle }
    @mining_thread = Thread.new { mining_cycle }
  end

  def entity_types
    [Manufactured::Ship,
     Manufactured::Station,
     Manufactured::Fleet]
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
    raise ArgumentError, "entity must be a ship, station, or fleet" if ![Manufactured::Ship,
                                                                         Manufactured::Station,
                                                                         Manufactured::Fleet].include?(entity.class)

    container = nil
    if entity.is_a?(Manufactured::Ship)
      raise ArgumentError, "ship id #{entity.id} already taken" if @ships.find{ |sh| sh.id == entity.id }
      raise ArgumentError, "ship #{entity} already created" if @ships.include?(entity)
      raise ArgumentError, "ship #{entity} must be valid" unless entity.valid?
      container = @ships

    elsif entity.is_a?(Manufactured::Station)
      raise ArgumentError, "station id #{entity.id} already taken" if @stations.find{ |st| st.id == entity.id }
      raise ArgumentError, "station #{entity} already created" if @stations.include?(entity)
      raise ArgumentError, "station #{entity} must be valid" unless entity.valid?
      container = @stations

    elsif entity.is_a?(Manufactured::Fleet)
      raise ArgumentError, "fleet id #{entity.id} already taken" if @fleets.find{ |fl| fl.id == entity.id }
      raise ArgumentError, "fleet #{entity} already created" if @fleets.include?(entity)
      raise ArgumentError, "fleet #{entity} must be valid" unless entity.valid?
      container = @fleets
    end

    @entities_lock.synchronize{
      container << entity
    }
  end

  def transfer_resource(from_entity, to_entity, resource_id, quantity)
    @entities_lock.synchronize{
      # TODO throw exception ?
      quantity = quantity.to_f
      return if from_entity.nil? || to_entity.nil? ||
                !from_entity.can_transfer?(to_entity, resource_id, quantity) ||
                !to_entity.can_accept?(resource_id, quantity)
      to_entity.add_resource(resource_id, quantity)
      from_entity.remove_resource(resource_id, quantity)
      return [from_entity, to_entity]
    }
  end

  # add new attack command to run
  def schedule_attack(args = {})
    @entities_lock.synchronize{
      cmd = AttackCommand.new(args)
      # TODO if replacing old command, invoke old command 'stopped' callbacks
      @attack_commands[cmd.id] = cmd
    }
  end

  # add new mining command to run
  def schedule_mining(args = {})
    @entities_lock.synchronize{
      cmd = MiningCommand.new(args)
      @mining_commands[cmd.id] = cmd
    }
  end

  # invoked in thread to periodically invoke attack commands
  def attack_cycle
    until @terminate_cycles
      @entities_lock.synchronize{
        # run attack if appropriate
        @attack_commands.each { |id, ac|
          ac.attack! if ac.attackable?
        }

        # remove attack commands no longer necessary
        @attack_commands.reject! { |id, ac| ac.remove? }

        # remove ships w/ <= 0 hp
        # TODO add deleted ships to a ship graveyard registry
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
        @mining_commands.each { |id, mc|
          if mc.minable?
            mc.ship.start_mining(mc.resource_source) unless mc.ship.mining?
            mc.mine!
          end
        }

        # remove mining commands no longer necessary
        to_remove = @mining_commands.keys.select { |id| @mining_commands[id].remove? }
        to_remove.each { |id|
          @mining_commands[id].ship.stop_mining
          @mining_commands.delete(id)
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
    # FIXME update to store attack + mining commands
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
