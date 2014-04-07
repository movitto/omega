# manufactured::stop_entity rjr definitions
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured::RJR
  # stop entity movement
  stop_entity = proc { |id|
    # retrieve / validate entity
    entity = registry.entity &with_id(id)
    raise DataNotFound,  id if entity.nil?
    raise ArgumentError, id unless entity.is_a?(Manufactured::Ship)
  
    # require modify on entity
    require_privilege :registry => user_registry, :any =>
      [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
       {:privilege => 'modify', :entity => 'manufactured_entities'}]
  
    # update the entity's location
    entity.location =
      node.invoke 'motel::get_location', 'with_id', entity.location.id
  
    # set entity's movement strategy to stopped
    entity.location.movement_strategy =
      Motel::MovementStrategies::Stopped.instance
    node.invoke('motel::update_location', entity.location)
    # TODO remove_callbacks?
  
    # return entity
    entity
  }

  STOP_METHODS = {:stop_entity => stop_entity}
end

def dispatch_manufactured_rjr_stop(dispatcher)
  m = Manufactured::RJR::STOP_METHODS
  dispatcher.handle 'manufactured::stop_entity', &m[:stop_entity]
end
