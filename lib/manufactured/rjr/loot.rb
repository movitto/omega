# manufactured::collect_loot rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'
require 'users/attributes/stats'

module Manufactured::RJR

# collect loot using the specified ship
collect_loot = proc { |ship_id, loot_id|
  # TODO also allow specification of resources through args

  # retrieve/validate ship and loot
  ship = registry.entity &with_id(ship_id)
  loot = registry.entity &with_id(loot_id)
  raise DataNotFound, ship_id if ship.nil? || !ship.is_a?(Ship)
  raise DataNotFound, loot_id if loot.nil? || !loot.is_a?(Loot)

  # require modify on the ship
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
     {:privilege => 'modify', :entity => 'manufactured_entities'}]

  # update ship's/loot's locations and solar systems
  ship.location =
    node.invoke('motel::get_location', 'with_id', ship.location.id)
  loot.location =
    node.invoke('motel::get_location', 'with_id', loot.location.id)
  ship.solar_system =
    node.invoke('cosmos::get_entity', 'with_location', ship.location.parent_id)
  loot.solar_system =
    node.invoke('cosmos::get_entity', 'with_location', loot.location.parent_id)

  # ensure loot can be tranferred to ship and ship can accept
  raise OperationError unless loot.resources.all? { |r|
                                loot.can_transfer?(ship, r) &&
                                ship.can_accept?(r)
                              }
  
  total = 0

  # run the transfer in the registry
  registry.safe_exec { |entities|
    # retrieve registry ship/loot
    s = entities.find &with_id(ship.id)
    l = entities.find &with_id(loot.id)

    # iterate over loot resources
    l.resources.each { |r|
      added = removed = false
      begin
        # transfer resource
        s.add_resource(r)    ; added   = true
        l.remove_resource(r) ; removed = true
        total += r.quantity

        # run collected_loot callbacks
        s.run_callbacks :collected_loot, r
      rescue Exception => e
      ensure
        # if resource was added to ship but not
        #  removed from loot, remove it from ship
        s.remove_resource(r) if added && !removed
      end
    }

    # if cargo is empty, delete loot from registry
    entities.delete(l)   if l.cargo_empty?
    entities.compact!
  }

  # update user attributes
  node.invoke('users::update_attribute', ship.user_id,
              Users::Attributes::LootCollected.id, total)

  # return ship
  registry.entity &with_id(ship.id)
}

LOOT_METHODS = { :collect_loot   => collect_loot }

end # module Manufactured::RJR

def dispatch_manufactured_rjr_loot(dispatcher)
  m = Manufactured::RJR::LOOT_METHODS
  dispatcher.handle 'manufactured::collect_loot', &m[:collect_loot]
end
