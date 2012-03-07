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
    return @last_attack_time.nil? || ((Time.now - @last_attack_time) > 1 / @attacker.attack_rate)
  end

  def attack!
    RJR::Logger.debug "invoking attack command #{@attacker.id} -> #{@defender.id}"

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

end
