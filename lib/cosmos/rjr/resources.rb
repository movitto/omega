# cosmos::set_resource,
# cosmos::get_resource_sources rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

set_resource = proc { |entity_id, resource, quantity|
  raise ArgumentError, "quantity must be an int or float >= 0" unless (quantity.is_a?(Integer) || quantity.is_a?(Float)) && quantity >= 0
  raise ArgumentError, "#{resource} must be a resource" unless resource.is_a?(Cosmos::Resource)

  entity = Cosmos::Registry.instance.find_entity(:name => entity_id)
  raise Omega::DataNotFound, "entity specified by #{entity_id} not found" if entity.nil?

  valid_types = Cosmos::Registry.instance.entity_types
  raise ArgumentError, "Invalid #{entity.class} entity specified, must be one of #{valid_types.inspect}" unless valid_types.include?(entity.class)

  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "cosmos_entity-#{entity.name}"},
                                             {:privilege => 'modify', :entity => 'cosmos_entities'}],
                                    :session => @headers['session_id'])
  raise ArgumentError, "#{resource} must be acceptable by entity #{entity}" unless entity.accepts_resource?(resource)

  Cosmos::Registry.instance.set_resource(entity_id, resource, quantity)
  nil
}

get_resource_sources = proc { 
  entity = Cosmos::Registry.instance.find_entity(:name => entity_id)
  raise Omega::DataNotFound, "entity specified by #{entity_id} not found" if entity.nil?
  Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entity.name}"},
                                             {:privilege => 'view', :entity => 'cosmos_entities'}],
                                    :session => @headers['session_id'])
  Cosmos::Registry.instance.resource_sources.select { |rs| rs.entity.name == entity_id }
}

def dispatch_resources(dispatcher)
  dispatcher.handle 'cosmos::set_resource', &set_resource
  dispatcher.handle 'cosmos::get_resource_sources', &get_resource_sources
end
