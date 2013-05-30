# [users::get_entities, users::get_entity] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users::RJR

# Retrieve all entities in registry matching criteria
get_entities = proc { |*args|
  # retrieve entities matching filters specified by args
  filters = filters_from_args args,
    :with_id  => proc { |e, id| e.id         == id },
    :of_type  => proc { |e, t|  e.class.to_s == t  }
  entities = Registry.instance.entities { |e| filters.all? { |f| f.call(e) }}

  # if id of entity is specified, only return single entity
  return_first = args.include?('with_id')
  if return_first
    entities = entities.first

    # make sure entity was found
    id = args[args.index('with_id') + 1]
    raise DataNotFound, id if entities.nil?

    # make sure user has view privileges on entity
    # FIXME should be users/roles
    require_privilege :any =>
      [{:privilege => 'view', :entity => "users_entity-#{entities.id}"},
       {:privilege => 'view', :entity => 'users_entities'}]

  # else return array of entities which user has access to
  else
    entities.reject! { |entity|
      !check_privilege :any =>
        [{:privilege => 'view', :entity => "users_entity-#{entity.id}"},
         {:privilege => 'view', :entity => 'users_entities'}]
    }
  end

  entities
}

GET_METHODS = { :get_entities => get_entities  }

end # module Users::RJR

def dispatch_get(dispatcher)
  m = Users::RJR::GET_METHODS
  dispatcher.handle ['users::get_entity', 'users::get_entities'],
                                               &m[:get_entities]
end
