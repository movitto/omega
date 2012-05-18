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

  # determine if we can attack using this attack command
  def attackable?
    # TODO make sure entities are within attacking distance
    return @last_attack_time.nil? || ((Time.now - @last_attack_time) > 1 / @attacker.attack_rate)
  end

  def attack!
    RJR::Logger.debug "invoking attack command #{@attacker.id} -> #{@defender.id}"

    @last_attack_time = Time.now

    # reduce defender's hp
    @defender.hp -= @attacker.damage_dealt

    # invoke defender's 'attacked' callbacks
    @defender.notification_callbacks.
              select { |c| c.type == :attacked}.
              each { |c|
      c.invoke 'attacked', @attacker, @defender
    }

    # check if defender has been destroyed
    if @defender.hp <= 0
      RJR::Logger.debug "#{@attacker.id} destroyed #{@defender.id}, marking for removal"

      # TODO clear defender's notification callbacks?

      # invoke defender's 'destroyed' callbacks
      @defender.notification_callbacks.
                select { |c| c.type == :destroyed}.
                each { |c|
        c.invoke 'destroyed', @attacker, @defender
      }

      # remove this attack command
      # TODO should be set elsewhere as well (such as when targets become too far apart)
      @remove = true

      # invoke defender's 'attacked_stop' callbacks
      @defender.notification_callbacks.
                select { |c| c.type == :attacked_stop}.
                each { |c|
        c.invoke 'attacked_stop', @attacker, @defender
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

  # determine if we can mine using this mining command
  def minable?
    # TODO make sure entities are within mining distance
    return @last_time_mined.nil? || ((Time.now - @last_time_mined) > (1 / @ship.mining_rate))
  end

  def mine!
    RJR::Logger.debug "invoking mining command #{@ship.id} -> #{@resource_source.id}"

    @last_time_mined = Time.now

    @resource_source.quantity -= @ship.mining_quantity
    @ship.add_resource @resource_source.resource, @ship.mining_quantity

    if @resource_source.quantity <= 0
      RJR::Logger.debug "#{@ship.id} depleted resource #{@resource_source.id}, marking for removal"

      # TODO implement resource_depleted & stopped_mining callbacks

      # remove this mining command
      # TODO should be set elsewhere as well (such as when targets become too far apart)
      @remove = true
    end
  end

  def remove?
    @remove
  end
end

end
