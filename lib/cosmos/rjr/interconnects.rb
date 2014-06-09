# cosmos::interconnections rjr definition
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'cosmos/rjr/init'
require 'motel/location'

module Cosmos::RJR

# retrieve galaxy system interconnections
interconnects = proc { |galaxy_id|
  galaxy = registry.entity &with_id(galaxy_id)

  raise DataNotFound, galaxy_id if galaxy.nil?
  # TODO argument error if galaxy is not a galaxy

  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'view', :entity => "cosmos_entity-#{galaxy.id}"},
     {:privilege => 'view', :entity => 'cosmos_entities'}]

  # TODO support a 'reverse' flag / method at some point
  # (systems mapped to others which have gates to them)

  # return hash of system id's to array of connected system id's
  galaxy_map =
    galaxy.children.map { |sys|
      [sys.id,  sys.jump_gates.collect { |jg| jg.endpoint_id }]
    }

  Hash[galaxy_map]
}

INTERCONNECTS_METHODS = { :interconnects => interconnects }

end # module Cosmos::RJR

def dispatch_cosmos_rjr_interconnects(dispatcher)
  m = Cosmos::RJR::INTERCONNECTS_METHODS
  dispatcher.handle 'cosmos::interconnects', &m[:interconnects]
end
