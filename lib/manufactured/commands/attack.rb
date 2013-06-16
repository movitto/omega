# Manufactured attack command definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/command'

module Manufactured
module Commands

# Represents action of one {Manufactured::Ship} attacking another 
#
# Registered with the registry by a client when attacker commences
# attacking and periodically run by registry until attacked stops,
# defender is destroyed, or one of several other conditions occur.
#
# Invokes {Manufactured::Callback}s registered with the attacker 
# and defender before/during/after the attack cycle with the event type,
# the attacking ship, and the defending ship as params
# 
# The callback events/types invoked include:
# * 'attacked_stop' - invoked on the attacker when attacker stops attacking
# * 'attacked_stop' - invoked on the defender when attacker stops attacking
# * 'attacked'      - invoked on the attacker when attacker actually launches the attack
# * 'defended'      - invoked on the defender when attacker actually launches the attack
# * 'destroyed'     - invoked on the defender if this attack cycle resulted in the defender hp becoming <= 0
class Attack < Omega::Server::Command

  # {Manufactured::Ship} performing the attack
  attr_accessor :attacker

  # {Manufactured::Ship} receiving that attack
  attr_accessor :defender

  # Return the unique id of this attack command.
  #
  # Currently a ship may only attack one other at a time,
  # TODO incorporate multiple weapons and area based weapons 
  # (multiple defenders) into this
  def id
    'attack-cmd-' + @attacker.id
  end

  # Manufactured::Commands::Attack initializer
  # @param [Hash] args hash of options to initialize attack command with
  # @option args [Manufactured::Ship] :attacker ship attacking the defender
  # @option args [Manufactured::Ship] :defender ship receiving attack from the attacker
  def initialize(args = {})
    attr_from_args args, :attacker => nil,
                         :defender => nil
    super(args)
  end

  def first_hook
    @attacker.start_attacking(@defender)
  end

  def before_hook
    # TODO update attacker/defender w/ locations (unless terminated?)
  end

  def after_hook
    # TODO write to registry?
  end

  def last_hook
    @attacker.stop_attacking

    # invoke attackers's 'attacked_stop' callbacks
    @attacker.run_callbacks('attacked_stop', @attacker, @defender)

    # invoke defender's 'defended_stop' callbacks
    @defender.run_callbacks(c.invoke 'defended_stop', @attacker, @defender)

    # check if defender has been destroyed
    if @defender.hp == 0
      RJR::Logger.debug "#{@attacker.id} destroyed #{@defender.id}"

      @defender.destroyed_by = @attacker

      # invoke defender's 'destroyed' callbacks
      @defender.run_callbacks('destroyed', @attacker, @defender)

      # create loot if necessary
      unless @defender.cargo_empty?
        # two entities (ship/loot) sharing same location
        loot = Manufactured::Loot.new :id => "#{@defender.id}-loot",
                                      :resources => @defender.resources,
                                      :location  => @defender.location
        # TODO add to registry
      end
    end
  end

  def should_run?
    super && @attacker.can_attack?(@defender)
  end

  def run!
    super
    RJR::Logger.debug "invoking attack command #{@attacker.id} -> #{@defender.id}"

    # TODO incorporate a hit / miss probability into this
    # TODO incorporate AC / other defense mechanisms into this
    # TODO delay between launching attack and it arriving at defender
    #   (depending on distance and projectile speed)

    # first reduce defender's shield then hp
    if @attacker.damage_dealt <= @defender.current_shield_level
      @defender.current_shield_level -= @attacker.damage_dealt

    else
      pips = (@attacker.damage_dealt - @defender.current_shield_level)
      @defender.hp -= pips
      @defender.current_shield_level = 0

      @defender.hp = 0 if @defender.hp < 0
    end

    # invoke attacker's 'attacked' callbacks
    @attacker.run_callbacks(c.invoke 'attacked', @attacker, @defender)

    # invoke defender's 'defended' callbacks
    @defender.run_callbacks(c.invoke 'defended', @attacker, @defender)
  end

end # class Attack
end # module Commands
end # module Omega
