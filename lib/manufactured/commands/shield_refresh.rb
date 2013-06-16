# Manufactured shield refresh command definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/command'

module Manufactured
module Commands

# Represents action of shield recharging on a {Manufactured::Ship}
#
# Associated with an attack command, will cease operation after attack
# finished and shield is fully refreshed
class ShieldRefresh < Omega::Server::Command
  # {Manufactured::Entity entity} whose shield is being refreshed
  attr_accessor :entity

  # {Manufacuted::Commands::Attack} attack command which this shield refresh
  #   command's lifecycle is tried to
  attr_accessor :attack_cmd

  # Return the unique id of this command.
  def id
    @entity.id
  end

  # Manufactured::Commands::ShieldRefresh initializer
  #
  # @param [Hash] args hash of options to initialize mining command with
  # @option args [Manufactured::Entity] :entity entity
  # @option args [Manufactured::Command] :check_command command which to checked to determine whether or not to continue
  def initialize(args = {})
    attr_from_args args, :entity => nil,
                         :attack_cmd => nil
    super(args)
  end

  def should_run?
    super && @entity.hp > 0 &&
    (attack_cmd.should_run? || @entity.shield_level < @entity.max_shield_level)
  end

  def run!
    RJR::Logger.debug "refreshing shield of #{@entity.id}"
    if @entity.shield_level < entity.max_shield_level
      pips =  (Time.now - @last_ran_at) * @entity.shield_refresh_rate
      @entity.shield_level += pips
      @entity.shield_level =
        entity.max_shield_level if entity.shield_level > entity.max_shield_level
    end
    super
  end

end # class ShieldRefresh
end # module Commands
end # module Omega
