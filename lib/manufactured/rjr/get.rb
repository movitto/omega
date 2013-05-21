# [manufactured::get, manufactured::get_entity,
#  manufactured::get_entities] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

manufactured_get_entities = proc { |*args|
  filter = {}
  # TODO also include_graveyard option?
  while qualifier = args.shift
    raise ArgumentError, "invalid qualifier #{qualifier}" unless ["of_type", "owned_by", "with_id", "with_location", "under", "include_loot"].include?(qualifier)
    val = args.shift
    raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
    qualifier = case qualifier
                  when "of_type"
                    :type
                  when "owned_by"
                    :user_id
                  when "with_id"
                    :id
                  when "with_location"
                    :location_id
                  when "under"
                    :parent_id
                  when "include_loot"
                    :include_loot
                end
    filter[qualifier] = val
  end

  # if user specified id or location, return the first (and only) result on its own
  return_first = filter.has_key?(:id) || filter.has_key?(:location_id)

  # ensure user exists if user_id is specified
  if filter.has_key?(:user_id)
    user = @@local_node.invoke_request('users::get_entity', 'with_id', filter[:user_id])
    raise Omega::DataNotFound, "user specified by #{user_id} not found" if user.nil?
  end

  # ensure system exists if parent_id is specified
  if filter.has_key?(:parent_id)
    parent = @@local_node.invoke_request('cosmos::get_entity', 'of_type', :solarsystem, 'with_name', filter[:parent_id])
    raise Omega::DataNotFound, "parent system specified by #{parent_id} not found" if parent.nil?
  end

  entities = Manufactured::Registry.instance.find(filter)

  entities.reject! { |entity|
    !Users::Registry.check_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                              {:privilege => 'view', :entity => 'manufactured_entities'}],
                                     :session => @headers['session_id'])

  }

  entities.each { |entity|
    Manufactured::Registry.instance.safely_run {
      entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))
    }
  }

  if return_first
    entities = entities.first
    raise Omega::DataNotFound, "manufactured entity specified by #{filter} not found" if entities.nil?
  end

  entities
}

def dispatch_get(dispatcher)
  dispatcher.handle ['manufactured::get',
                     'manufactured::get_entity',
                     'manufactured::get_entities']
                      &manufactured_get_entities
end
