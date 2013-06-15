# [cosmos::get_entities, cosmos::get_entity] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/rjr/init'

module Cosmos::RJR
# retrieve entities filtered by args
get_entities = proc { |*args|
  # retrieve entities matching filters specified by args
  filters = filters_from_args args,
    :with_id       => proc { |e, id|   e.id == id           },
    :with_name     => proc { |e, name| e.name == id         },
    :of_type       => proc { |e, type| e.class.to_s == type },
    :with_location => proc { |e, l|    e.location.id == l.is_a?(String) ? l : l.id }
  entities = registry.entities { |e| filters.all? { |f| f.call(e) }}

  # update entities' locations & children's
  entities.each { |entity|
    entity.location = node.invoke('motel::get_location', 'with_id', entity.location.id)
    entity.location.parent = entity.parent.location if entity.parent
    entity.each_child { |e, c|
      c.location = node.invoke('motel::get_location', 'with_id', c.location.id)
      c.location.parent = e.location
    }
  }
# FIXME update entities in registry

  # if id of entity is specified, only return single entity
  return_first = args.include?('with_id') || args.include?('with_name')
  if return_first
    entities = entities.first

    # make sure entity was found
    id   = args[args.index('with_id') + 1] if args.include?('with_id')
    name = args[args.index('with_name') + 1] if args.include?('with_name')
    raise DataNotFound, (id.nil? ? name : id) if entities.nil?

    # make sure the user has privileges on the specified entity
    require_privilege :registry => user_registry, :any =>
      [{:privilege => 'view', :entity => "cosmos_entity-#{entities.id}"},
       {:privilege => 'view', :entity => 'cosmos_entities'}]

  # else filter out entities which user does not have access to
  else
    entities.reject! { |entity|
      !check_privilege :registry => user_registry, :any =>
         [{:privilege => 'view', :entity => "cosmos_entity-#{entity.id}"},
          {:privilege => 'view', :entity => 'cosmos_entities'}]
    }
  end

  # return entities
  entities
}

GET_METHODS = { :get_entities => get_entities }

end # module Cosmos::RJR

def dispatch_cosmos_rjr_get(dispatcher)
  m = Cosmos::RJR::GET_METHODS
  dispatcher.handle ['cosmos::get_entities', 'cosmos::get_entity'],
                                                 &m[:get_entities]
end
