# Manufactured shield refresh command definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'omega/server/command'

module Manufactured
module Commands

# Represents action of shield recharging on a {Manufactured::Ship}
#
# Associated with an attack command, will cease operation after attack
# finished and shield is fully refreshed
class ShieldRefresh < Omega::Server::Command
  include Omega::Server::CommandHelpers

  # {Manufactured::Entity entity} whose shield is being refreshed
  attr_accessor :entity

  # {Manufactured::Commands::Attack} attack command which this shield refresh
  #   command's lifecycle is tried to
  attr_accessor :attack_cmd

  # Return the unique id of this command.
  def id
    "shield-refresh-cmd-#{@entity.nil? ? "" : @entity.id.to_s}"
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

  def before_hook
    # update entity from registry
    @entity = retrieve(@entity.id)

    # update cmd from registry
    @attack_cmd = retrieve(@attack_cmd.id) if @attack_cmd
  end

  def after_hook
    # persist entity to registry
    update_registry(@entity)
  end

  def should_run?
    super && @entity.hp > 0 &&
    (@entity.shield_level < @entity.max_shield_level)
  end

  def run!
    ::RJR::Logger.debug "refreshing shield of #{@entity.id}"
    @last_ran_at ||= Time.now
    if @entity.shield_level < @entity.max_shield_level
      pips =  (Time.now - @last_ran_at) * @entity.shield_refresh_rate
      @entity.shield_level += pips
      @entity.shield_level =
        entity.max_shield_level if entity.shield_level > entity.max_shield_level
    end

    # set last_ran_at after time check
    super
  end

  def remove?
    # remove if the attack command has been deleted or is otherwise finished
    # and shield is at max level
    (@attack_cmd.nil? || @attack_cmd.remove?) &&
    (@entity.hp == 0 || (@entity.shield_level == @entity.max_shield_level))
  end

   # Convert command to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:attack_cmd => attack_cmd,
          :entity  => entity}.merge(cmd_json)
     }.to_json(*a)
   end

end # class ShieldRefresh
end # module Commands
end # module Omega
