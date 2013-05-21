# manufactured::attack_entity rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

manufactured_attack_entity = proc { |attacker_entity_id, defender_entity_id|
  raise ArgumentError, "attacker and defender entities must be different" if attacker_entity_id == defender_entity_id

  attacker = Manufactured::Registry.instance.find(:id => attacker_entity_id, :type => "Manufactured::Ship").first
  defender = Manufactured::Registry.instance.find(:id => defender_entity_id, :type => "Manufactured::Ship").first

  raise Omega::DataNotFound, "ship specified by #{attacker_entity_id} (attacker) not found"  if attacker.nil?
  raise Omega::DataNotFound, "ship specified by #{defender_entity_id} (defender) not found"  if defender.nil?

  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{attacker.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])
  # FIXME not sure if it's feasible to grant attacker permission to view defender, how to tackle this
  Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{defender.id}"},
                                             {:privilege => 'view', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])

  # raise error if attacker cannot attack defender
  before_attack_cycle = lambda { |cmd|
    cmd.attacker.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.attacker.location.id))
    cmd.defender.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.defender.location.id))
    raise Omega::OperationError, "#{attacker} cannot attack #{defender}" unless attacker.can_attack?(defender)
  }

  # update locations before attack
  before_attack = lambda { |cmd|
    cmd.attacker.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.attacker.location.id))
    cmd.defender.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.defender.location.id))
  }

  # after destroyed, invoke 'users::set_attribute' to set
  # 'ships_user_destroyed' and 'user_ships_destroyed' user attributes
  after_attack = lambda { |cmd|
    if cmd.defender.hp == 0 && cmd.defender.destroyed_by.id == cmd.attacker.id
      @@local_node.invoke_request('users::update_attribute', cmd.attacker.user_id, Users::Attributes::ShipsUserDestroyed.id, 1)
      @@local_node.invoke_request('users::update_attribute', cmd.defender.user_id, Users::Attributes::UserShipsDestroyed.id, 1)
    end
  }

  cmd = Manufactured::Registry.instance.schedule_attack   :attacker  => attacker,
                                                          :defender  => defender,
                                                          :before    => before_attack,
                                                          :after     => after_attack,
                                                          :first     => before_attack_cycle

  Manufactured::Registry.instance.schedule_shield_refresh :entity    => defender,
                                                          :check_command => cmd

  [attacker, defender]
}

def dispatch_attack(dispatcher)
  dispatcher.handle 'manufactured::attack_entity',
                      &manufactured_attack_entity
  # dispatcher.handle('manufactured::stop_attack', 'TODO')
end
