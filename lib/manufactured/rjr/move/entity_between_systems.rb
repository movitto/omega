# manufactured::move entity between systems helper
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/proxy'

require 'manufactured/events/system_jump'

module Manufactured::RJR
  # Move an entity between systems
  def move_entity_between_systems(entity, sys)
  
    # if moving ship ensure
    # - a jump gate within trigger distance is nearby
    # - ship is not docked
    #
    # (TODO optional transport delay / jump time)
    # (TODO optional skipping this check if user has sufficient
    #       privs modify-manufactured_entities ?)
    if entity.is_a?(Manufactured::Ship)
      near_jg =
        !entity.solar_system.jump_gates.find { |jg|
          jg.endpoint_id == sys.id &&
          (jg.location - entity.location) < jg.trigger_distance
         }.nil?
      raise OperationError, "#{entity} not by jump gate" unless near_jg
      raise OperationError, "#{entity} docked"           if entity.docked?
    end
  
    # set parent and location
    # TODO set loc x, y, z to vicinity of reverse jump gate
    #       (gate to current system in destination system) if it exists ?
    orig_parent = entity.parent
    entity.parent = sys
    entity.location.movement_strategy =
      Motel::MovementStrategies::Stopped.instance
  
    # update location and remove movement callbacks
    node.invoke('motel::update_location',  entity.location)
    node.invoke('motel::remove_callbacks', entity.location.id, 'movement')
    node.invoke('motel::remove_callbacks', entity.location.id, 'rotation')
  
    if !sys.proxy_to.nil?
      proxy = Omega::Server::ProxyNode.with_id(sys.proxy_to).login
  
      # TODO invoke users::get with_id entity.user_id &
      # if not present users::create_user ?
      # or perhaps err out ('user not authorized to jump to remote system')?
  
      proxy.invoke 'manufactured::create_entity', entity
  
      # XXX remove entity from local registry
      registry.delete &with_id(entity.id)
      node.invoke('motel::delete_location', entity.location.id)
  
      # also remove related privs
      user_role = "user_role_#{entity.user_id}"
      owner_permissions_for(entity).each { |p,e|
        node.invoke('users::remove_privilege', user_role, p, e)
      }
  
    else
      # update registry entity
      registry.update entity, &with_id(entity.id)
    end
  
    # run new system_jump event in registry
    event = Manufactured::Events::SystemJump.new :old_system => orig_parent,
                                                 :entity => entity
    registry << event
  
    nil
  end
end
