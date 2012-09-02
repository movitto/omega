# Manufactured command definitions
#
# Manufactured commands encapsulate actions between entities
# and are run periodically by the registry.
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured

# Represents action of one {Manufactured::Ship} attacking another 
#
# Registered with the registry by a client when attacker commences
# attacking and periodically run by registry until attacked stops,
# defender is destroyed, or one of several other conditions occur.
#
# Invokes various Manufactured::Callback handlers upon various
# events.
class AttackCommand
  # {Manufactured::Ship} performing the attack
  attr_accessor :attacker

  # {Manufactured::Ship} receiving that attack
  attr_accessor :defender

  # Time of last time {#attack!} was invoked
  attr_accessor :last_attack_time

  # Hash of command sequence events to callbale handlers to invoke on those events.
  # Valid values for keys include: :before
  attr_accessor :hooks

  # Manufactured::AttackCommand initializer
  # @param [Hash] args hash of options to initialize attack command with
  # @option args [Manufactured::Ship] :attacker ship attacking the defender
  # @option args [Manufactured::Ship] :defender ship receiving attack from the attacker
  # @option args [Callable] :before callable object to register with the 'before' hooks
  def initialize(args = {})
    @attacker = args[:attacker]
    @defender = args[:defender]
    @remove   = false

    @hooks = { :before => [] }
    @hooks[:before] << args[:before] if args.has_key?(:before)
  end

  # Return the unique id of this attack command.
  #
  # Checked by the registry to ensure no two commands correspond to the same operation.
  # Currently returns attacker id indicating a ship may only attack one other at a time,
  # at some point we may want to incorporate multiple weapons and area based weapons 
  # (multiple defenders) into this
  def id
    @attacker.id
  end

  # Returns boolean indicating if attack! can / should be called.
  #
  # Determines if enough time has lapsed since the last attack to compensate
  # for the attacker's attack rate
  # @return [true,false] indicating if attack! can / cannot be called
  def attackable?
    # elapsed time between mining cycles is less than ship's attack rate
    return @last_attack_time.nil? || ((Time.now - @last_attack_time) > 1 / @attacker.attack_rate)
  end

  # Ensure attack command is still valid and perform one attack cycle.
  #
  # This method ensures the attack would still be valid (ships are close
  # enough, etc) and then launches the attack. 
  #
  # Also invokes {Manufactured::Callback}s registered with the attacker 
  # and defender before/during/after the attack cycle with the event type,
  # the attacking ship, and the defending ship as params
  # 
  # The callback events/types invoked include:
  # * 'attacked_stop' - invoked on the attacker when attacker stops attacking
  # * 'attacked_stop' - invoked on the defender when attacker stops attacking
  # * 'attacked'      - invoked on the attacker when attacker actually launches the attack
  # * 'defended'      - invoked on the defender when attacker actually launches the attack
  # * 'destroyed'     - invoked on the defender if this attack cycle resulted in the defender hp becoming <= 0
  def attack!
    RJR::Logger.debug "invoking attack command #{@attacker.id} -> #{@defender.id}"

    # FIXME ensure attacker has not been destroyed itself
    # ensure entities are within attacking distance
    unless @attacker.can_attack?(@defender)
      # invoke attackers's 'attacked_stop' callbacks
      @attacker.notification_callbacks.
                select { |c| c.type == :attacked_stop}.
                each { |c|
        c.invoke 'attacked_stop', @attacker, @defender
      }

      # invoke defender's 'defended_stop' callbacks
      @defender.notification_callbacks.
                select { |c| c.type == :defended_stop}.
                each { |c|
        c.invoke 'defended_stop', @attacker, @defender
      }

      @remove = true
      return
    end

    @last_attack_time = Time.now

    # TODO incorporate a hit / miss probability into this
    # TODO incorporate shields / AC / other defense mechanisms into this
    # TODO delay between launching attack and it arriving at defender
    #   (depending on distance and projectile speed)

    # reduce defender's hp
    @defender.hp -= @attacker.damage_dealt

    # invoke attacker's 'attacked' callbacks
    @attacker.notification_callbacks.
              select { |c| c.type == :attacked}.
              each { |c|
      c.invoke 'attacked', @attacker, @defender
    }

    # invoke defender's 'defended' callbacks
    @defender.notification_callbacks.
              select { |c| c.type == :defended}.
              each { |c|
      c.invoke 'defended', @attacker, @defender
    }

    # check if defender has been destroyed
    if @defender.hp <= 0
      RJR::Logger.debug "#{@attacker.id} destroyed #{@defender.id}, marking for removal"

      # invoke defender's 'destroyed' callbacks
      @defender.notification_callbacks.
                select { |c| c.type == :destroyed}.
                each { |c|
        c.invoke 'destroyed', @attacker, @defender
      }

      # remove this attack command
      @remove = true

      # invoke attackers's 'attacked_stop' callbacks
      @attacker.notification_callbacks.
                select { |c| c.type == :attacked_stop}.
                each { |c|
        c.invoke 'attacked_stop', @attacker, @defender
      }

      # invoke defender's 'defended_stop' callbacks
      @defender.notification_callbacks.
                select { |c| c.type == :defended_stop}.
                each { |c|
        c.invoke 'defended_stop', @attacker, @defender
      }
    end
      
  end

  # Returns boolean indicating if this attack command should be removed
  # @return [true,false]
  def remove?
    @remove
  end

end

# Represents action of one {Manufactured::Ship} mining a {Cosmos::ResourceSource}
#
# Registered with the registry by a client when miner commences
# miner and periodically run by registry until mining stops,
# as the result of one of conditions occurring
#
# Invokes various Manufactured::Callback handlers upon various
# events.
class MiningCommand
  # Mining {Manufactured::Ship ship}
  attr_accessor :ship

  # {Cosmos::ResourceSource} being mined
  attr_accessor :resource_source

  # Time of last time {#mine!} was invoked
  attr_accessor :last_time_mined

  # Hash of command sequence events to callbale handlers to invoke on those events.
  # Valid values for keys include: :before
  attr_accessor :hooks

  # Manufactured::MiningCommand initializer
  # @param [Hash] args hash of options to initialize mining command with
  # @option args [Manufactured::Ship] :ship miner ship
  # @option args [Cosmos::ResourceSource] :resource_source resource source being mined
  # @option args [Callable] :before callable object to register with the 'before' hooks
  def initialize(args = {})
    @ship            = args[:ship]
    @resource_source = args[:resource_source]
    @remove          = false

    @hooks = { :before => [] }
    @hooks[:before] << args[:before] if args.has_key?(:before)
  end

  # Return the unique id of this mining command.
  #
  # Checked by the registry to ensure no two commands correspond to the same operation.
  # Currently returns miner id indicating a ship may only mine one source at a time,
  # at some point we may want to incorporate multiple resources into this (TODO)
  def id
    @ship.id
  end

  # Returns boolean indicating if mine! can / should be called.
  #
  # Determines if enough time has lapsed since the last mining operation to compensate
  # for the miners's mining rate
  # @return [true,false] indicating if mining! can / cannot be called
  def minable?
    # elapsed time between mining cycles is less than ship's mining rate
    return @last_time_mined.nil? || ((Time.now - @last_time_mined) > (1 / @ship.mining_rate))
  end

  # Ensure mining command is still valid and perform one mining cycle.
  #
  # This method ensures the mining would still be valid (miner/resource
  # are close enough, etc) and then launches the operation. 
  #
  # Also invokes {Manufactured::Callback}s registered with the miner 
  # before/during/after the mining cycle with the event type,
  # and various other parameters
  # 
  # The callback events/types invoked include:
  # * 'resource_depeleted' - invoked when resource source quantity becomes <= 0 with event, miner, and resource source as params
  # * 'mining_stopped'     - invoked when miner stops mining with event, stopped reason, ship, and resource source as params. Reasons include:
  # ** 'mining_distance_exceeded'
  # ** 'ship_cargo_full'
  # ** 'ship_docked'
  # ** 'resource_depleted' (also invokes 'resource_depeleted' callback)
  # * 'resource_collected' - invoked when miner collects the resource from the source, with event, miner, resource source, and quantity mined during this operation as params
  def mine!
    RJR::Logger.debug "invoking mining command #{@ship.id} -> #{@resource_source.id}"

    # if resource_source has less than mining_quantity only transfer that amount
    mining_quantity = @ship.mining_quantity
    mining_quantity = @resource_source.quantity if @resource_source.quantity < mining_quantity

    unless @ship.can_mine?(@resource_source) && @ship.can_accept?(@resource_source.resource.id, mining_quantity)
      @remove = true # must issue subsequent mining requests
      reason = ''

      # ship & resource are too far apart or in different systems
      if (@ship.location.parent.id != @resource_source.entity.location.parent.id ||
          (@ship.location - @resource_source.entity.location) > @ship.mining_distance)
        reason = 'mining_distance_exceeded'

      # ship is at max capacity
      elsif (@ship.cargo_quantity + @ship.mining_quantity) >= @ship.cargo_capacity
        reason = 'ship_cargo_full'

      # ship has become docked
      elsif @ship.docked?
        reason = 'ship_docked'

      elsif @resource_source.quantity <= 0
        RJR::Logger.debug "#{@ship.id} depleted resource #{@resource_source.id}, marking for removal"
        @ship.notification_callbacks.
              select { |c| c.type == :resource_depleted}.
              each { |c|
          c.invoke 'resource_depleted', @ship, @resource_source
        }

        reason = 'resource_depleted'

      end

      @ship.notification_callbacks.
            select { |c| c.type == :mining_stopped }.
            each   { |c|
        c.invoke 'mining_stopped', reason, @ship, @resource_source
      }

      return
    end

    @last_time_mined = Time.now

    removed_resource = false
    resource_transferred = false
    begin
      @resource_source.quantity -= mining_quantity
      removed_resource = true
      @ship.add_resource @resource_source.resource.id, mining_quantity
      resource_transferred = true
    rescue Exception => e
      @resource_source.quantity += mining_quantity if removed_resource
    end

    if resource_transferred
      @ship.notification_callbacks.
            select { |c| c.type == :resource_collected}.
            each { |c|
        c.invoke 'resource_collected', @ship, @resource_source, mining_quantity
      }
    end
  end

  # Returns boolean indicating if this mining command should be removed
  # @return [true,false]
  def remove?
    @remove
  end
end

end
