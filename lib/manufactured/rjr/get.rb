# [manufactured::get, manufactured::get_entity,
#  manufactured::get_entities] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'

module Manufactured::RJR
# retrieve manufactured entities filtered by args
get_entities = proc { |*args|
  filters = filters_from_args args,
    :with_id       => proc { |e, i| e.id          == i },
    :of_type       => proc { |e, t| e.class.to_s  == t },
    :owned_by      => proc { |e, o| e.user_id     == o },
    :with_location => proc { |e, l| e.location.id == l },
    :under         => proc { |e, p| e.system_id   == p }
  filters.unshift proc { |e| !e.kind_of?(Omega::Server::Command) }
  filters.unshift proc { |e| !e.kind_of?(Omega::Server::Event) &&
                             !e.kind_of?(Omega::Server::EventHandler) }
  entities = registry.entities { |e| filters.all? { |f| f.call(e) }}

  # update entities locations from motel
  entities.each { |e|
    e.location =
      node.invoke 'motel::get_location', 'with_id', e.location.id
  }

  # if id or location id is specified, return single entity
  return_first = args.include?('with_id') || args.include?('with_location')
  if return_first
    entities = entities.first

    # make sure the entity was found
    id  = args[args.index('with_id') + 1] if args.include?('with_id')
    loc = args[args.index('with_location') + 1] if id.nil?
    raise DataNotFound, id.nil? ? loc : id if entities.nil?

    # make sure the user has privileges on the specified entity
    require_privilege :registry => user_registry, :any =>
      [{:privilege => 'view', :entity => "manufactured_entity-#{entities.id}"},
       {:privilege => 'view', :entity => 'manufactured_entities'}]

  # else return an array of entities which the user has access to
  else
    entities.reject! { |entity|
      !check_privilege :registry => user_registry, :any =>
        [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
         {:privilege => 'view', :entity => 'manufactured_entities'}]
    }
  end

  # return entities
  entities
}

GET_METHODS = { :get_entities => get_entities }
end

def dispatch_manufactured_rjr_get(dispatcher)
  m = Manufactured::RJR::GET_METHODS
  dispatcher.handle ['manufactured::get',
                     'manufactured::get_entity',
                     'manufactured::get_entities'],
                      &m[:get_entities]
end
