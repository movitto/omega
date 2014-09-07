# manufactured::follow_entity rjr definitions
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Manufactured::RJR
  # follow entity, keeping specified distance away, and also pointing to it
  follow_entity = proc { |*args|
    id             = args[0]
    target_id      = args[1]
    distance       = args[2]
    strategy       = args[3] || :follow
    strategy_class = Motel.strategy_class_for strategy

    # ensure different entity id's specified
    raise ArgumentError, "#{id} == #{target_id}" if id == target_id

    # retrieve entities from registry, validate
    entity = registry.entity &with_id(id)
    target = registry.entity &with_id(target_id)
    raise DataNotFound, id        if entity.nil?
    raise DataNotFound, target_id if target.nil?
    raise ArgumentError, entity   unless entity.is_a?(Ship)
    raise ArgumentError, target   unless target.is_a?(Ship)
  
    # ensure valid distance specified
    raise ArgumentError, distance unless distance.numeric? && distance > 0

    # validate strategy class
    raise ArgumentError, strategy if strategy_class.nil?
  
    # require modify on follower, view on followee
    require_privilege :registry => user_registry, :any =>
      [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
       {:privilege => 'modify', :entity => 'manufactured_entities'}]
    require_privilege :registry => user_registry, :any =>
      [{:privilege => 'view', :entity => "manufactured_entity-#{target.id}"},
       {:privilege => 'view', :entity => 'manufactured_entities'}]
  
    # update the locations and systems
    entity.location =
      node.invoke('motel::get_location', 'with_id', entity.location.id)
    target.location =
      node.invoke('motel::get_location', 'with_id', target.location.id)
    entity.solar_system =
      node.invoke('cosmos::get_entity', 'with_location', entity.location.parent_id)
    target.solar_system =
      node.invoke('cosmos::get_entity', 'with_location', target.location.parent_id)
  
    # ensure entities are in the same system
    raise ArgumentError,
      "#{entity.system_id} != #{target.system_id}" if entity.system_id !=
                                                             target.system_id
  
    # ensure entity isn't docked
    raise OperationError, "#{entity} is docked" if entity.docked?
  
    # set the movement strategy, update the location
    strategy_args = {:distance => distance,
                        :speed => 1,
                    :max_speed => entity.movement_speed,
                 :acceleration => entity.acceleration,
          :tracked_location_id => target.location.id,
                    :rot_theta => entity.rotation_speed}
    entity.location.movement_strategy = strategy_class.new strategy_args

    node.invoke('motel::update_location', entity.location)
  
    # return the entity
    entity
  }

  FOLLOW_METHODS = {:follow_entity => follow_entity}
end

def dispatch_manufactured_rjr_follow(dispatcher)
  m = Manufactured::RJR::FOLLOW_METHODS
  dispatcher.handle 'manufactured::follow_entity', &m[:follow_entity]
end
