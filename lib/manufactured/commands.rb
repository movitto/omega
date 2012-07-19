# Manufactured command definitions
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured

class AttackCommand
  attr_accessor :attacker
  attr_accessor :defender
  attr_accessor :last_attack_time

  def initialize(args = {})
    @attacker = args[:attacker]
    @defender = args[:defender]
    @remove   = false
  end

  def id
    # TODO incorporate weapon id into this
    @attacker.id
  end

  # determine if we can attack using this attack command
  def attackable?
    # elapsed time between mining cycles is less than ship's attack rate
    return @last_attack_time.nil? || ((Time.now - @last_attack_time) > 1 / @attacker.attack_rate)
  end

  def attack!
    RJR::Logger.debug "invoking attack command #{@attacker.id} -> #{@defender.id}"

    # ensure entities are within attacking distance
    # FIXME update these locations before this check
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

  def remove?
    @remove
  end

end

class MiningCommand
  attr_accessor :ship
  attr_accessor :resource_source
  attr_accessor :last_time_mined

  def initialize(args = {})
    @ship            = args[:ship]
    @resource_source = args[:resource_source]
    @remove          = false
  end

  def id
    # TODO allow one ship to mine multipe resources (incorporate incrementer here w/ per-ship max)
    @ship.id
  end

  # determine if we can mine using this mining command
  def minable?
    # elapsed time between mining cycles is less than ship's mining rate
    return @last_time_mined.nil? || ((Time.now - @last_time_mined) > (1 / @ship.mining_rate))
  end

  def mine!
    RJR::Logger.debug "invoking mining command #{@ship.id} -> #{@resource_source.id}"

    # if resource_source has less than mining_quantity only transfer that amount
    mining_quantity = @ship.mining_quantity
    mining_quantity = @resource_source.quantity if @resource_source.quantity < mining_quantity

    # FIXME refresh locations first
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
        reason = 'resource_source_depleted'

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

    if @resource_source.quantity <= 0
      RJR::Logger.debug "#{@ship.id} depleted resource #{@resource_source.id}, marking for removal"

      @ship.notification_callbacks.
            select { |c| c.type == :resource_depleted}.
            each { |c|
        c.invoke 'resource_depleted', @ship, @resource_source
      }

      @ship.notification_callbacks.
            select { |c| c.type == :mining_stopped }.
            each   { |c|
        c.invoke 'mining_stopped', 'resource_depleted', @ship, @resource_source
      }

      # remove this mining command
      @remove = true
    end
  end

  def remove?
    @remove
  end
end

end
