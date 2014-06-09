# [cosmos::get_entities, cosmos::get_entity] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'cosmos/rjr/init'
require 'motel/location'

module Cosmos::RJR
# retrieve entities filtered by args
get_entities = proc { |*args|
  # retrieve entities matching filters specified by args
  filters = filters_from_args args,
    :with_id       => proc { |e, id|   e.id == id           },
    :with_name     => proc { |e, name| e.name == name       },
    :of_type       => proc { |e, type| e.class.to_s == type },
    :with_location => proc { |e, l|    e.location.id == (l.is_a?(Motel::Location) ? l.id : l) },
    :children      => proc { |e, v|    true }, # TODO rename to with_children ?
    :recursive     => proc { |e, v|    true },
    :select        => proc { |e, v| true }
  entities = registry.entities { |e| filters.all? { |f| f.call(e) }}

  # filters which apply to children/descendents of
  # entities retrieved, by default return all children
  include_children   = !args.include?('children')  || args[args.index('children')  + 1]
  recursive_children = !args.include?('recursive') || args[args.index('recursive') + 1]

  entities.map! { |entity|
    # update entities' locations & children's
    entity.location = node.invoke('motel::get_location',
                                  'with_id',   entity.location.id,
                                  'children',  include_children,
                                  'recursive', recursive_children)
    entity.location.parent = entity.parent.location if entity.parent

    # allow user to disable child retrieval for performance
    if include_children
      entity.each_child { |e, c|
        c.location = node.invoke('motel::get_location', 'with_id', c.location.id)
        c.location.parent = e.location
      }

      # only return direct descendants
      unless recursive_children
        entity.children.each { |c|
          # TODO swap w/ id instead of blanking? (and in motel)
          c.children = []
        }
      end

    # allow user to disable child retrieval for performance
    else
      entity.children.each_index { |i|
        entity.children[i] = entity.children[i].id
      }
    end

    # only include properties specified by the user
    args.include?('select') ?
      filter_properties(entity, :allow => args[args.index('select') + 1]) :
      entity
  }

  # if id of entity is specified, only return single entity
  return_first = args.include?('with_id')   ||
                 args.include?('with_name') ||
                 args.include?('with_location')
  if return_first
    entities = entities.first

    # make sure entity was found
    id   = args[args.index('with_id')       + 1] if args.include?('with_id')
    name = args[args.index('with_name')     + 1] if args.include?('with_name')
    loc  = args[args.index('with_location') + 1] if args.include?('with_location')
    raise DataNotFound, (id.nil? ? (name.nil? ? loc : name) : id) if entities.nil?

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
