# manufactured::attack_entity rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'
require 'manufactured/commands/attack'
require 'manufactured/commands/shield_refresh'

module Manufactured::RJR

# register new attack command w/ the local registry
attack_entity = proc { |attacker_id, defender_id|
  # ensure different entity id's specified
  raise ArgumentError,
        "attacker_id == defender_id" if attacker_id == defender_id

  # lookup entities
  attacker = registry.entity &with_id(attacker_id)
  defender = registry.entity &with_id(defender_id)
  raise DataNotFound, attacker_id if attacker.nil? || !attacker.is_a?(Ship)
  raise DataNotFound, defender_id if defender.nil? || !defender.is_a?(Ship)

  # require modify on attacker, view on defender
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "manufactured_entity-#{attacker.id}"},
     {:privilege => 'modify', :entity => 'manufactured_entities'}]
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'view', :entity => "manufactured_entity-#{defender.id}"},
     {:privilege => 'view', :entity => 'manufactured_entities'}]


  # create new attack command, add to registry
  atk = Commands::Attack.new :attacker  => attacker, :defender  => defender
  registry << atk

  # create new shield refresh command, add to registry
  shr = Commands::ShieldRefresh.new :entity => defender, :attack_cmd => atk
  registry << shr

  # return attacker, defender
  [attacker, defender]
}

ATTACK_METHODS = { :attack_entity   => attack_entity }

end # module Manufactured::RJR

def dispatch_manufactured_rjr_attack(dispatcher)
  m = Manufactured::RJR::ATTACK_METHODS
  dispatcher.handle 'manufactured::attack_entity', &m[:attack_entity]
  # dispatcher.handle('manufactured::stop_attack', 'TODO')
end
