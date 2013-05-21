# [users::get_entities, users::get_entity] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

users_get_entities = proc { |*args|
  filter = {}
  while qualifier = args.shift
    raise ArgumentError, "invalid qualifier #{qualifier}" unless ["of_type", "with_id"].include?(qualifier)
    val = args.shift
    raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
    qualifier = case qualifier
                  when "of_type"
                    :type
                  when "with_id"
                    :id
                end
    filter[qualifier] = val
  end

  return_first = filter.has_key?(:id)

  entities = Users::Registry.instance.find(filter)

  if return_first
    entities = entities.first
    raise Omega::DataNotFound, "users entity specified by #{filter.inspect} not found" if entities.nil?
    Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "users_entity-#{entities.id}"},
                                               {:privilege => 'view', :entity => 'users_entities'}],
                                      :session   => @headers['session_id'])

  else
    entities.reject! { |entity|
      !Users::Registry.check_privilege(:any => [{:privilege => 'view', :entity => "users_entity-#{entity.id}"},
                                                {:privilege => 'view', :entity => 'users_entities'}],
                                       :session => @headers['session_id'])
    }
  end

  entities
}

def dispatch_get(dispatcher)
  dispatcher.handle ['users::get_entity', 'users::get_entities'],
                                             &users_get_entities
end
