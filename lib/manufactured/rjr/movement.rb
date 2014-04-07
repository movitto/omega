# manufactured::move_entity, manufactured::follow_entity,
# manufactured::stop_entity rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO split up into seperate modules

require 'omega/server/proxy'
require 'manufactured/rjr/init'
require 'manufactured/events/system_jump'

module Manufactured::RJR

# Move a ship in a single system
def move_ship_in_system(entity, loc)
  # TODO may want to incorporate fuel into this at some point

  # verify we are processing ships here, also ensure not docked
  raise OperationError, "#{entity} not ship" unless entity.is_a?(Ship)
  raise OperationError, "#{entity} docked"   unless !entity.docked?

  # calculate distance to move along each access
  dx = loc.x - entity.location.x
  dy = loc.y - entity.location.y
  dz = loc.z - entity.location.z
  distance = loc - entity.location
  raise OperationError, "#{entity} at location" if distance < 1

  # Create linear movement strategy w/ movement trajectory
  linear =
    Motel::MovementStrategies::Linear.new :dx => dx/distance,
                                          :dy => dy/distance,
                                          :dz => dz/distance,
                                          :speed => entity.movement_speed

  # calculate the orientation difference
  od = entity.location.orientation_difference(*loc.coordinates)

  # TODO introduce point_to_target flag in Linear movement strategy
  # (similar to Follow) & use here, removing the need for the follow distinction

  # if we are close enough to correct orientation,
  # register linear movement strategy with entity
  if od.first.abs < (Math::PI / 32)
    entity.location.movement_strategy = linear

  # if we need to adjust orientation before moving,
  # register rotation movement strategy w/ entity
  else
    # create the rotation movement strategy
    rotate =
      Motel::MovementStrategies::Rotate.new \
        :rot_theta => (od[0] * entity.rotation_speed),
        :rot_x     =>  od[1],
        :rot_y     =>  od[2],
        :rot_z     =>  od[3]

    # register rotation w/ location, linear as next movement strategy
    entity.location.movement_strategy = rotate
    entity.location.next_movement_strategy = linear

    # track location rotation
    node.invoke('motel::track_rotation', entity.location.id, *od)
  end

  # track location movement and update location
  node.invoke('motel::track_movement', entity.location.id, distance)
  node.invoke('motel::update_location', entity.location)
  nil
end

# Move station in single system
def move_station_in_system(station, loc)
  # Verify we are processing stations here
  raise OperationError, "#{station} not a station" unless station.is_a?(Station)

  # When moving station, we only permit orbiting around system's star
  is_orbiting = loc.ms.is_a?(Motel::MovementStrategies::Elliptical)
  on_orbit    = is_orbiting ? loc.ms.intersects?(loc) : false
  raise OperationError, "#{station} must orbit star" unless is_orbiting
  raise OperationError,
    "station location #{station.location.coords} not on orbit" unless on_orbit

  # update movement strategy
  station.location.movement_strategy = loc.ms
  node.invoke('motel::update_location', station.location)

  # TODO update dock'd ship movement strategies?

  nil
end

# Move entity in single system
def move_entity_in_system(entity, loc)
  entity.is_a?(Ship) ?    move_ship_in_system(entity, loc) :
                       move_station_in_system(entity, loc)
end

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

# follow entity, keeping specified distance away, and also pointing to it
follow_entity = proc { |id, target_id, distance|
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
  entity.location.movement_strategy =
    Motel::MovementStrategies::Follow.new :distance => distance,
                                :speed => entity.movement_speed,
                     :tracked_location_id => target.location.id,
                                       :point_to_target => true,
                       :rotation_speed => entity.rotation_speed

  node.invoke('motel::update_location', entity.location)

  # return the entity
  entity
}

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

MOVEMENT_METHODS = { :move_entity   => move_entity,
                     :follow_entity => follow_entity,
                     :stop_entity   => stop_entity }

end # module Manufactured::RJR

def dispatch_manufactured_rjr_movement(dispatcher)
  m = Manufactured::RJR::MOVEMENT_METHODS
  dispatcher.handle 'manufactured::move_entity',   &m[:move_entity]
  dispatcher.handle 'manufactured::follow_entity', &m[:follow_entity]
  dispatcher.handle 'manufactured::stop_entity',   &m[:stop_entity]
end
