# Manufactured attack command definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'omega/server/command'

module Manufactured
module Commands

# Represents action of one {Manufactured::Ship} attacking another 
#
# Registered with the registry by a client when attacker commences
# attacking and periodically run by registry until attacked stops,
# defender is destroyed, or one of several other conditions occur.
#
# Invokes {Omega::Server::Callback}s registered with the attacker 
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
  include Omega::Server::CommandHelpers

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
    id = @attacker.nil? ? "" : @attacker.id.to_s
    "attack-cmd-#{id}"
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
    # update entities from registry
    @attacker = retrieve(@attacker.id)
    @defender = retrieve(@defender.id)

    # update locations from motel
    @attacker.location =
      invoke 'motel::get_location', 'with_id', @attacker.location.id
    @defender.location =
      invoke 'motel::get_location', 'with_id', @defender.location.id
  end

  def after_hook
    # persist entities to the registry
    update_registry(@attacker)
    update_registry(@defender)
  end

  def last_hook
    @attacker.stop_attacking
 
    # check if defender has been destroyed
    if @defender.hp == 0
      ::RJR::Logger.debug "#{@attacker.id} destroyed #{@defender.id}"

# TODO
    # set 'ships_user_destroyed' and 'user_ships_destroyed' attributes
    # node.invoke('users::update_attribute', @attacker.user_id,
    #             Users::Attributes::ShipsUserDestroyed.id,  1)
    # node.invoke('users::update_attribute', @defender.user_id,
    #             Users::Attributes::UserShipsDestroyed.id,  1)

      # create loot if necessary
      unless @defender.cargo_empty?
        # two entities (ship/loot) sharing same location
        loot = Manufactured::Loot.new :id => "#{@defender.id}-loot",
                 :location          => @defender.location,
                 :system_id         => @defender.system_id,
                 :movement_strategy => Motel::MovementStrategies::Stopped.instance,
                 :cargo_capacity    => @defender.cargo_capacity
        @defender.resources.each { |r| loot.add_resource r }
        registry << loot
      end

      # invoke defender's 'destroyed' callbacks
      run_callbacks(@defender, 'destroyed_by', @attacker)
    end

    # invoke attackers's 'attacked_stop' callbacks
    run_callbacks(@attacker, 'attacked_stop', @defender)

    # invoke defender's 'defended_stop' callbacks
    run_callbacks(@defender, 'defended_stop', @attacker)
  end

  def should_run?
    super && @attacker.can_attack?(@defender)
  end

  def run!
    super
    ::RJR::Logger.debug "invoking attack command #{@attacker.id} -> #{@defender.id}"

    # TODO incorporate a hit / miss probability into this
    # TODO incorporate AC / other defense mechanisms into this
    # TODO delay between launching attack and it arriving at defender
    #   (depending on distance and projectile speed)

    # first reduce defender's shield then hp
    if @attacker.damage_dealt <= @defender.shield_level
      @defender.shield_level -= @attacker.damage_dealt

    else
      pips = (@attacker.damage_dealt - @defender.shield_level)
      @defender.hp -= pips
      @defender.shield_level = 0

      if @defender.hp <= 0
        @defender.hp = 0
        @defender.destroyed_by = @attacker
      end
    end

    # invoke attacker's 'attacked' callbacks
    run_callbacks(@attacker, 'attacked', @defender)

    # invoke defender's 'defended' callbacks
    run_callbacks(@defender, 'defended', @attacker)
  end

  def remove?
    # remove if defender is destoryed
    # TODO also if no longer attackable for whatever reason (eg ships too far apart)
    @defender.hp == 0
  end

   # Convert command to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:attacker => attacker,
          :defender => defender}.merge(cmd_json)
     }.to_json(*a)
   end

end # class Attack
end # module Commands
end # module Manufactured
