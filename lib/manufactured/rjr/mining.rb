# manufactured::start_mining rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'
require 'manufactured/commands/mining'

module Manufactured::RJR

# register new mining command w/ the local registry
start_mining = proc { |ship_id, resource_id|
  # retrieve miner, validate
  ship = registry.entity &with_id(ship_id)
  raise DataNotFound, ship_id if ship.nil? || !ship.is_a?(Ship)

  # retrieve resource to mine
  # TODO incorporate resource scanning distance & capabilities into this
  resource =
    begin node.invoke('cosmos::get_resource', resource_id)
    rescue Exception => e ; raise DataNotFound, resource_id end


  # require modify manufactured entity
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
     {:privilege => 'modify', :entity => 'manufactured_entities'}]

  # create mining command and register it
  cmd = Commands::Mining.new :ship => ship, :resource => resource
  registry << cmd

  # return miner
  ship
}

MINING_METHODS = { :start_mining   => start_mining }

end # module Manufactured::RJR

def dispatch_manufactured_rjr_mining(dispatcher)
  m = Manufactured::RJR::MINING_METHODS
  dispatcher.handle 'manufactured::start_mining', &m[:start_mining]
  # dispatcher.handle('manufactured::stop_mining', 'TODO')
end
