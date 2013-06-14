# cosmos::create_resource,cosmos::get_resources rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/rjr/init'

module Cosmos::RJR
# create the specified resource
create_resource = proc { |resource|
  # ensure resource is a valid resource
  raise ArgumentError, resource unless resource.is_a?(Resource) &&
                                       resource.valid? &&
                                       resource.quantity > 0

  # retrieve entity
  entity = registry.entity &with_id(resource.entity_id)
  raise DataNotFound, resource.entity if entity.nil?

  # ensure entity can accept resource
  raise ArgumentError, entity unless entity.can_accept?(resource)

  # require modify cosmos entities
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "cosmos_entity-#{entity.id}"},
     {:privilege => 'modify', :entity => 'cosmos_entities'}]

  # Add resource to entity
  entity.add_resource(resource)
# TODO update entity in registry

  # return nil
  nil
}

# retrieve all resources for entity
get_resources = proc { |entity_id|
  # retrieve entity from registry
  entity = registry.entity &with_id(entity_id)
  raise DataNotFound, entity_id if entity.nil?

  # ensure user has view privileges on entity
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'view', :entity => "cosmos_entity-#{entity.id}"},
     {:privilege => 'view', :entity => 'cosmos_entities'}]

  # return resources
  entity.resources
}

RESOURCES_METHODS = { :create_resource => create_resource,
                      :get_resources   => get_resources }

end # module Cosmos::RJR

def dispatch_cosmos_rjr_resources(dispatcher)
  m = Cosmos::RJR::RESOURCES_METHODS
  dispatcher.handle 'cosmos::set_resource', &m[:create_resource]
  dispatcher.handle 'cosmos::get_resource_sources', &m[:get_resources]
end
