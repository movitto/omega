# Manufactured entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'singleton'

module Manufactured

class Registry
  include Singleton

  # ships we are tracking
  def ships
    ret = []
    @entities_lock.synchronize {
      @ships.each { |s| ret << s }
    }
    return ret
  end

  # stations we are tracking
  def stations
    ret = []
    @entities_lock.synchronize {
      @stations.each { |s| ret << s }
    }
    return ret
  end

  # fleets we are tracking
  def fleets
    ret = []
    @entities_lock.synchronize {
      @fleets.each { |f| ret << f }
    }
    return ret
  end

  # holds ships which have been destroyed
  attr_reader :ship_graveyard

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
    @ships    = []
    @stations = []
    @fleets   = []
    @attack_commands = {}
    @mining_commands = {}

    @ship_graveyard = []

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

  # runs a block of code as an operation protected by the entities lock
  def safely_run(*args, &bl)
    @entities_lock.synchronize {
      bl.call *args
    }
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
                            (parent_id.nil? || (entity.parent && (entity.parent.name  == parent_id))) &&
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

    return nil if container.nil?

    @entities_lock.synchronize{
      container << entity
    }

    return entity
  end

  def transfer_resource(from_entity, to_entity, resource_id, quantity)
    @entities_lock.synchronize{
      # TODO throw exception ?
      quantity = quantity.to_f
      return if from_entity.nil? || to_entity.nil? ||
                !from_entity.can_transfer?(to_entity, resource_id, quantity) ||
                !to_entity.can_accept?(resource_id, quantity)
      begin
        to_entity.add_resource(resource_id, quantity)
        from_entity.remove_resource(resource_id, quantity)
      rescue Exception => e
        return nil
      end

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
          # run 'before' hooks
          ac.hooks[:before].each { |hook|
            hook.call ac
          }

          ac.attack! if ac.attackable?
        }

        # remove attack commands no longer necessary
        @attack_commands.reject! { |id, ac| ac.remove? }

        # remove ships w/ <= 0 hp and
        # add deleted ships to ship graveyard registry
        destroyed = []
        @ships.delete_if { |sh| destroyed << sh if sh.hp <= 0 }
        @ship_graveyard += destroyed
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
          # run 'before' hooks
          mc.hooks[:before].each { |hook|
            hook.call mc
          }

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
    # FIXME update to store attack + mining commands & ship graveyard
    nil
  end

  # restore state of the registry from the specified stream
  def restore_state(io)
    io.each { |json|
      entity = JSON.parse(json)
      if entity.is_a?(Manufactured::Ship) || entity.is_a?(Manufactured::Station)
        create(entity)
      end
    }
    nil
  end


end

end
