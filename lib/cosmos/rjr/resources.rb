# cosmos::set_resource,cosmos::get_resources rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/rjr/init'

module Cosmos::RJR
# create the specified resource
set_resource = proc { |resource|
  # ensure resource is a valid resource
  raise ArgumentError, resource unless resource.is_a?(Resource) &&
                                       resource.valid? &&
                                       resource.quantity > 0

  # retrieve entity
  entity = registry.entity &with_id(resource.entity_id)
  raise DataNotFound, resource.entity if entity.nil?

  # ensure entity can accept resource
  raise ArgumentError, entity unless entity.accepts_resource?(resource)

  # require modify cosmos entities
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "cosmos_entity-#{entity.id}"},
     {:privilege => 'modify', :entity => 'cosmos_entities'}]

  # Set resource on entity
  registry.safe_exec { |entities|
    rentity = entities.find &with_id(entity.id)
    rentity.set_resource(resource)
  }

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

RESOURCES_METHODS = { :set_resource => set_resource,
                      :get_resources   => get_resources }

end # module Cosmos::RJR

def dispatch_cosmos_rjr_resources(dispatcher)
  m = Cosmos::RJR::RESOURCES_METHODS
  dispatcher.handle 'cosmos::set_resource', &m[:set_resource]
  dispatcher.handle 'cosmos::get_resources', &m[:get_resources]
end
