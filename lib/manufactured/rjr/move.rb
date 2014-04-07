# manufactured::move_entity rjr definitions
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'
require 'manufactured/rjr/move/entity_in_system'
require 'manufactured/rjr/move/entity_between_systems'

module Manufactured::RJR
  # Move entity either in a linear fashion in a system or between
  # systems provided there is a jump gate near by
  move_entity = proc { |id, loc|
    # lookup entity, ensure it belongs to a valid type
    entity = registry.entity &with_id(id)
    raise DataNotFound, id if entity.nil?
    raise ValidationError, entity unless [Ship,Station].include?(entity.class)
    raise ValidationError, entity unless !entity.is_a?(Ship) || entity.alive?
  
    # require modify on manufactured_entity
    require_privilege :registry => user_registry, :any =>
      [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
       {:privilege => 'modify', :entity => 'manufactured_entities'}]
  
    # verify location
    # TODO only for ship? (if entity is a station, set to loc if nil?)
    raise ValidationError, loc unless loc.is_a?(Motel::Location)
  
    # update the entity's location & solar system
    entity.location =
      node.invoke('motel::get_location', 'with_id', entity.location.id)
    entity.solar_system =
      node.invoke('cosmos::get_entity',  'with_location', entity.location.parent_id)
  
    # lookup target system
    parent_id = loc.parent_id.nil? ? entity.system_id : loc.parent_id
    parent =
      begin node.invoke('cosmos::get_entity', 'with_location', parent_id)
      rescue Exception => e ; raise DataNotFound, parent_id end
    raise ValidationError, parent unless parent.is_a?(Cosmos::Entities::SolarSystem)
  
    # if parents don't match, we are moving entity between systems
    if entity.parent.id != parent.id
      move_entity_between_systems(entity, parent)
  
    # else move location within the system
    else
      move_entity_in_system(entity, loc)
    end
  
    # return entity
    entity
  }

  MOVE_METHODS = {:move_entity => move_entity}
end

def dispatch_manufactured_rjr_move(dispatcher)
  m = Manufactured::RJR::MOVE_METHODS
  dispatcher.handle 'manufactured::move_entity', &m[:move_entity]
end
