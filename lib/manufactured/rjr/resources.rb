# manufactured::add_resource, manufactured::transfer_resource,
# rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'

module Manufactured::RJR

# adds the specified resource to the specified entity,
# XXX would rather not have but needed by other subsystems
add_resource = proc { |entity_id, resource|
  # require local transport
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)

  # require modify manufactured_resources
  require_privilege(:registry  => user_registry,
                    :privilege => 'modify',
                    :entity => 'manufactured_resources')

  # retrieve/validate entity
  entity = registry.entity &with_id(entity_id)
  raise DataNotFound, entity_id if entity.nil?

  # validate resource
  raise ArgumentError,
        resource unless resource.valid? && resource.quantity > 0

  # update the entity in the registry
  registry.safe_exec { |entities|
    entities.find(&with_id(entity.id)).add_resource resource
  }

  # return entity
  entity
}

RESOURCES_METHODS = { :add_resource => add_resource }

end # module Manufactured::RJR

def dispatch_manufactured_rjr_resources(dispatcher)
  m = Manufactured::RJR::RESOURCES_METHODS
  dispatcher.handle 'manufactured::add_resource',      &m[:add_resource]
  dispatcher.handle 'manufactured::transfer_resource', &m[:transfer_resource]
end
