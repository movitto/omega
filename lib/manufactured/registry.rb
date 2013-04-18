# Manufactured entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'singleton'

module Manufactured

# Primary server side entity tracker for Manufactured module.
#
# Provides a thread safe registry through which manufactured
# entity heirarchies and resources can be accessed.
#
# Singleton class, access via Manufactured::Registry.instance.
class Registry
  include Singleton

  # Return array of ships being managed
  # @return [Array<Manufactured::Ship>]
  def ships
    ret = []
    @entities_lock.synchronize {
      @ships.each { |s| ret << s }
    }
    return ret
  end

  # Return array of stations being managed
  # @return [Array<Manufactured::Station>]
  def stations
    ret = []
    @entities_lock.synchronize {
      @stations.each { |s| ret << s }
    }
    return ret
  end

  # Return array of loot being managed
  # @return [Array<Manufactured::Loot>]
  def loot
    ret = []
    @entities_lock.synchronize {
      @loot.values.each { |f| ret << f }
    }
    return ret
  end

  # [Array<Manufactured::Ship>] array of ships that have been destroyed
  attr_reader :ship_graveyard

  # [Array<Manufactured::AttackCommand>] attack commands clients has issued to be regularily run
  attr_reader :attack_commands

  # [Array<Manufactured::MiningCommand>] mining commands clients has issued to be regularily run
  attr_reader :mining_commands

  # [Array<Manufactured::ConstructionCommand>] construction commands clients has issued to be run after a set time
  attr_reader :construction_commands

  # [Array<Manufactured::SheildRefreshCommand>] shield refresh commands to be regularily run
  attr_reader :shield_refresh_commands

  # Time attack thread sleeps between attack cycles
  ATTACK_POLL_DELAY = 0.5 # TODO make configurable?

  # Time mining thread sleeps between mining cycles
  MINING_POLL_DELAY = 0.5 # TODO make configurable?

  # Time construction thread sleeps between construction cycles
  CONSTRUCTION_POLL_DELAY = 1.0 # TODO make configurable?

  # Time shield takes to refresh
  SHIELD_REFRESH_DELAY = 0.5 # TODO make configurable?

  # Manufactured::Registry initializer
  def initialize
    init
  end

  # Reinitialize the Manufactured::Registry
  #
  # Clears all local trackers and starts threads to
  # run attack and mining cycles
  def init
    @ships    = []
    @stations = []
    @attack_commands = {}
    @mining_commands = {}
    @construction_commands = {}
    @shield_refresh_commands = {}

    @ship_graveyard = []

    @loot = {}

    terminate
    @terminate_cycles = false
    @entities_lock = Mutex.new
    @attack_thread = Thread.new { attack_cycle }
    @mining_thread = Thread.new { mining_cycle }
    @construction_thread = Thread.new { construction_cycle }
    @shield_thread = Thread.new { shield_refresh_cycle }
  end

  # Return array of classes of manufactured entity types
  def entity_types
    [Manufactured::Ship,
     Manufactured::Station]
  end

  # Return boolean indicating if the various subsystem is running
  def subsys_running?(subsys)
    statuses = ['run', 'sleep']

    !@terminate_cycles &&
    case subsys
    when :attack then
      !@attack_thread.nil? && statuses.include?(@attack_thread.status)
    when :mining then
      !@mining_thread.nil? && statuses.include?(@mining_thread.status)
    when :construction then
      !@construction_thread.nil? && statuses.include?(@construction_thread.status)
    when :shield then
      !@shield_thread.nil? && statuses.include?(@shield_thread.status)
    else
      false
    end
  end

  # Return boolean indicating if registry is running its various worker threads
  def running?
    subsys_running?(:attack) && subsys_running?(:mining) &&
    subsys_running?(:construction) && subsys_running?(:shield)
  end

  # Terminate registry worker threads
  def terminate
    @terminate_cycles = true

    @attack_thread.join unless @attack_thread.nil?
    @mining_thread.join unless @mining_thread.nil?
    @construction_thread.join unless @construction_thread.nil?
    @shield_thread.join unless @shield_thread.nil?
  end

  # Run the specified block of code as a protected operation.
  #
  # This should be used when updating any manufactured entities outside
  # the scope of registry operations to protect them from concurrent access.
  #
  # @param [Array<Object>] args catch-all array of arguments to pass to block on invocation
  # @param [Callable] bl block to invoke
  def safely_run(*args, &bl)
    @entities_lock.synchronize {
      bl.call *args
    }
  end

  # Unlock the registry lock, run the specified block of code, then lock again
  #
  # XXX not the prettiest, see invocations for why its needed
  #
  # @param [Array<Object>] args catch-all array of arguments to pass to block on invocation
  # @param [Callable] bl block to invoke
  def unsafely_run(*args, &bl)
    @entities_lock.unlock
    bl.call *args
    @entities_lock.lock
  end

  # Lookup and return entities in registry.
  #
  # By default, with no arguments, returns a flat list of all entities
  # tracked by the registry. Takes a hash of arguments to filter entities
  # by.
  #
  # TODO params to check / require privileges and raise error if entities not found
  #
  # @param [Hash] args arguments to filter manufatured entities with
  # @option args [String] :id string id to match
  # @option args [String] :parent_id string name of entity containing manufactured entities to match
  # @option args [String] :user_id string user id of entity ownining manufactured entities to match
  # @option args [String,:symbol] :type string class name of entities to match
  # @option args [Integer] :location_id integer location id  to match, if specified first matching result will be returned, nil if none found
  # @option args [Integer] :include_graveyard boolean indicating if graveyard should be included in search
  # @return [Array<ManufacturedEntity>] matching manufactured entities if any
  def find(args = {})
    to_search = children
    reqs      = []

    args.keys.each { |k|
      case k
      when :id then
        reqs << proc { |e| e.id == args[:id] }
      when :parent_id then
        reqs << proc { |e| e.parent && e.parent.name == args[:parent_id] }
      when :user_id then
        reqs << proc { |e| e.user_id == args[:user_id] }
      when :type then
        reqs << proc { |e| e.class.to_s == args[:type] }
      when :location_id then
        reqs << proc { |e| e.location && e.location.id == args[:location_id] }
      when :include_graveyard then
        to_search += graveyard
      when :include_loot then
        to_search += loot
      end
    }

# FIXME not protected while entity attributes may be being modified elsewhere (and in other registries)
@entities_lock.synchronize{
    to_search.select { |e| reqs.all? { |r| r.call(e) } }
}
  end

  # Return child ships and stations tracked by the registry
  # @return [Array<Manufactured::Ship,Manfuactured::Station>]
  def children
    children = []
    @entities_lock.synchronize{
      children = @ships + @stations
    }
    children
  end

  # Return entities in the ship graveyard
  # @return [Array<Manufactured::Ship>]
  def graveyard
    entities = []
    @entities_lock.synchronize{
      entities = Array.new(@ship_graveyard)
    }
    entities
  end

  # Return boolean indicating if child specified by given id can be found
  #
  # @param [String] child_id id of child entity to search for
  # @return [true,false] indicating if registry has child
  def has_child?(child_id)
    @entities_lock.synchronize{
      return !@ships.find    { |s| s.id == child_id }.nil? ||
             !@stations.find { |s| s.id == child_id }.nil?
    }
  end

  # Add child manufactured entity to registry
  #
  # Performs basic checks to ensure entity can added to registry
  # before adding to appropriate array.
  #
  # Invokes optional block if specified
  #
  # @param [Cosmos::ManufacturedEntity] entity entity to add to registry
  # @param [Callable] &bl block to call atomically upon entity being added to registry
  # @raise ArgumentError if entity cannot be added to registry for whatever reason
  # @return [Cosmos::ManufacturedEntity] entity added to the registry
  def create(entity, &bl)
    raise ArgumentError, "entity must be a ship or station" if ![Manufactured::Ship,
                                                                 Manufactured::Station].include?(entity.class)

    container = nil
    if entity.is_a?(Manufactured::Ship)
      raise ArgumentError, "ship id #{entity.id} already taken" if @ships.find{ |sh| sh.id == entity.id }
      raise ArgumentError, "ship #{entity} already created" if @ships.include?(entity)
      raise ArgumentError, "ship #{entity} must be valid" unless entity.valid?
      if entity.hp > 0
        container = @ships
      else
        container = @ship_graveyard
      end

    elsif entity.is_a?(Manufactured::Station)
      raise ArgumentError, "station id #{entity.id} already taken" if @stations.find{ |st| st.id == entity.id }
      raise ArgumentError, "station #{entity} already created" if @stations.include?(entity)
      raise ArgumentError, "station #{entity} must be valid" unless entity.valid?
      container = @stations

    end

    return nil if container.nil?

    @entities_lock.synchronize{
      container << entity
      bl.call entity if bl
    }

    return entity
  end

  # Perform resource transfer operation between manufactured entities
  #
  # @param [Manufactured::Entity] from_entity entity intiating transfer
  # @param [Manufactured::Entity] to_entity entity to receivereceived resources
  # @param [String] resource_id string id of the reosurce
  # @param [Integer] quantity amount of reosurce to transfer
  # @return [Array<Manufactured::Entity,Manufactured::Entity>, nil] array containing from_entity and to_entity or nil if transfer could not take place
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

  # Register new {Manufactured::AttackCommand} to be run during attack cycle
  #
  # @param [Hash] args args to intialize the attack command with
  def schedule_attack(args = {})
    @entities_lock.synchronize{
      cmd = AttackCommand.new(args)

      cmd.hooks[:first].each { |hook|
        hook.call cmd
      }

      # TODO if replacing old command, invoke old command 'stopped' callbacks
      @attack_commands[cmd.id] = cmd
    }
  end

  # Register new {Manufactured::MiningCommand} to be run during mining cycle
  #
  # @param [Hash] args args to intialize the mining command with
  def schedule_mining(args = {})
    @entities_lock.synchronize{
      cmd = MiningCommand.new(args)

      cmd.hooks[:first].each { |hook|
        hook.call cmd
      }

      @mining_commands[cmd.id] = cmd
    }
  end

  # Register new {Manufactured::ConstructionCommand} to be run during construction cycle
  #
  # @param [Hash] args args to intialize the construction command with
  def schedule_construction(args = {})
    @entities_lock.synchronize{
      cmd = ConstructionCommand.new(args)
      @construction_commands[cmd.id] = cmd
    }
  end

  # Register new {Manufactured::ShieldRefreshCommand} to be run duning shield refresh cycle
  #
  # @param [Hash] args args to initialize the shield refresh command with
  def schedule_shield_refresh(args = {})
    @entities_lock.synchronize{
      cmd = ShieldRefreshCommand.new(args)
      @shield_refresh_commands[cmd.id] = cmd
    }
  end

  # Run attack commands until instructed to stop
  #
  # @see #terminate
  def attack_cycle
    until @terminate_cycles
      @entities_lock.synchronize{
        # run attack if appropriate
        @attack_commands.each { |id, ac|
          # run 'before' hooks
          ac.hooks[:before].each { |hook|
            hook.call ac
          }

          if ac.attackable?
            ac.attacker.start_attacking(ac.defender) unless ac.attacker.attacking?
            ac.attack!
          end

          # run 'after' hooks
          ac.hooks[:after].each { |hook|
            hook.call ac
          }
        }

        # remove attack commands no longer necessary
        to_remove = @attack_commands.keys.select { |id| @attack_commands[id].remove? }
        to_remove.each { |id|
          @attack_commands[id].attacker.stop_attacking
          @attack_commands.delete(id)
        }

        # remove ships w/ <= 0 hp and
        # add deleted ships to ship graveyard registry
        destroyed = @ships.select { |sh| sh.hp <= 0 }
        destroyed.each { |sh|
          @ships.delete(sh)

          # create loot if necessary
          unless sh.cargo_empty?
            # two entities (ship/loot) sharing same location
            loot = Manufactured::Loot.new :id => "#{sh.id}-loot",
                                          :resources => sh.resources,
                                          :location  => sh.location
            @loot[loot.id] = loot
          end
        }
        # FIXME stop mining, movement, attacking, etc
        @ship_graveyard += destroyed
      }

      sleep ATTACK_POLL_DELAY
    end
  end

  # Run mining commands until instructed to stop
  #
  # @see #terminate
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

  # Run construction commands until instructed to stop
  #
  # @see #terminate
  def construction_cycle
    until @terminate_cycles
      @entities_lock.synchronize{
        # process construction commands
        @construction_commands.each { |id, cc|
          # run 'before' hooks
          cc.hooks[:before].each { |hook|
            hook.call cc
          }
          cc.construction_cycle
        }

        # remove construction commands no longer necessary
        to_remove = @construction_commands.keys.select { |id| @construction_commands[id].remove? }
        to_remove.each { |id|
          @construction_commands.delete(id)
        }
      }

      sleep CONSTRUCTION_POLL_DELAY
    end
  end

  # Run shield refresh cycle until instructed to stop
  def shield_refresh_cycle
    until @terminate_cycles
      @entities_lock.synchronize{
        # run shield refresh command
        @shield_refresh_commands.each { |id, src|
          src.run!
        }

        # remove commands no longer necessary
        to_remove = @shield_refresh_commands.keys.select { |id| @shield_refresh_commands[id].remove? }
        to_remove.each { |id|
          @shield_refresh_commands.delete(id)
        }
      }
      sleep SHIELD_REFRESH_DELAY
    end
  end

  # Set loot to registry. If empty deletes loot, else adds / updates loot record
  #
  # @param [Manufactured::Loot] loot loot to add to / update in registry
  def set_loot(loot)
    @entities_lock.synchronize{
      if loot.quantity == 0
        @loot.delete(loot.id)
      else
        @loot[loot.id] = loot
      end
    }
  end

  # Save state of the registry to specified io stream
  def save_state(io)
    children.each { |entity| 
      io.write entity.to_json + "\n"
    }
    graveyard.each { |entity|
      io.write entity.to_json + "\n"
    }

    # not storing attack + mining commands
    #  (storing hooks is not feasible, plus clients
    #   can relaunch commands when server is brought back up)
    nil
  end

  # Restore state of the registry from the specified io stream
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
