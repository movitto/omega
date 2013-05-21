# manufactured::collect_loot rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

manufactured_collect_loot = proc { |ship_id, loot_id|
  # TODO also allow specification of resource_id / quantity through args

  ship = Manufactured::Registry.instance.find(:id => ship_id, :type => 'Manufactured::Ship').first
  loot = Manufactured::Registry.instance.loot.find { |l| l.id == loot_id }
  raise Omega::DataNotFound, "ship specified by #{ship_id} not found" if ship.nil?
  raise Omega::DataNotFound, "loot specified by #{loot_id} not found" if loot.nil?

  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])

  Manufactured::Registry.instance.safely_run {
    # update entity's location
    ship.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', ship.location.id))
  }

  # ensure within the transfer distance
  # TODO add a can_collect? method to ship
  raise Omega::OperationError, "ship too far from loot" unless ship.location - loot.location <= ship.transfer_distance

  # TODO also support partial transfers
  raise Omega::OperationError, "ship cannot accept loot" unless ship.can_accept?('', loot.quantity)

  # TODO move to a registry operation, add 'collected' notification callbacks
  total = Manufactured::Registry.instance.collect_loot(ship, loot)

  # update user attributes
  @@local_node.invoke_request('users::update_attribute', sh.user_id,
                              Users::Attributes::LootCollected.id, total)

  # FIXME this is what deletes empty loot, need to uncomment
  # and make atomic w/ loot transfer operation above
  #Manufactured::Registry.instance.set_loot(loot)

  ship
}

def dispatch_loot(dispatcher)
  dispatcher.handle 'manufactured::collect_loot',
                      &manufactured_collect_loot
end
