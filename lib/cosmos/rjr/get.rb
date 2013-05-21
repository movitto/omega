# [cosmos::get_entities, cosmos::get_entity] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

get_entities = proc { |*args|
  filter = {}
  while qualifier = args.shift
    raise ArgumentError, "invalid qualifier #{qualifier}" unless ["of_type", "with_id", "with_name", "with_location"].include?(qualifier)
    val = args.shift
    raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
    qualifier = case qualifier
                  when "of_type"
                    :type
                  when "with_id"
                    :name
                  when "with_name"
                    :name
                  when "with_location"
                    :location
                end
    filter[qualifier] = val
  end

  entities = Cosmos::Registry.instance.find_entity(filter)

  return_first = false
  unless entities.is_a?(Array)
    raise Omega::DataNotFound, "entity not found with params #{filter.inspect}" if entities.nil?
    Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entities.name}"},
                                               {:privilege => 'view', :entity => 'cosmos_entities'}],
                                      :session => @headers['session_id'])

    return_first = true
    entities = [entities]
  end

  entities.reject! { |entity|
    raised = false
    begin
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entity.name}"},
                                                 {:privilege => 'view', :entity => 'cosmos_entities'}],
                                        :session => @headers['session_id'])
    rescue Omega::PermissionError => e
      raised = true
    end
    raised
  }

  # raise Omega::DataNotFound if entities.empty? (?)
  entities.each{ |entity|
    if entity.has_children?
      entity.each_child { |parent, child|
        Cosmos::Registry.instance.safely_run {
          child.location = @@local_node.invoke_request('motel::get_location', 'with_id', child.location.id)
          child.location.parent = parent.location
        }
      }
    end
  }

  0.upto(entities.size-1) { |i|
    entity = entities[i]
    Cosmos::Registry.instance.safely_run {
      # update locations w/ latest from the tracker
      entity.location = @@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id) if entity.location
      entity.location.parent = entity.parent.location if entity.parent
    }
  }

  return_first ? entities.first : entities
}

def dispatch_get_entities(dispatcher)
  dispatcher.handle ['cosmos::get_entities', 'cosmos::get_entity'],
                                                    &get_entities
end
