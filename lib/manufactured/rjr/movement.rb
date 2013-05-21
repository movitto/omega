# manufactured::move_entity, manufactured::follow_entity,
# manufactured::stop_entity rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

manufactured_move_entity = proc { |id, new_location|
  entity = Manufactured::Registry.instance.find(:id => id).first
  parent = new_location.parent_id.nil? ? entity.parent : @@local_node.invoke_request('cosmos::get_entity', 'of_type', :solarsystem, 'with_location', new_location.parent_id)
  
  raise ArgumentError, "invalid location #{new_location} specified" unless new_location.is_a?(Motel::Location)
  
  raise Omega::DataNotFound, "manufactured entity specified by #{id} not found"  if entity.nil?
  raise Omega::DataNotFound, "parent system specified by location #{new_location.parent_id} not found" if parent.nil?
  
  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])
  
  # raise exception if entity or parent is invalid
  raise ArgumentError, "Must specify ship or station to move" unless entity.is_a?(Manufactured::Ship) || entity.is_a?(Manufactured::Station)
  raise ArgumentError, "Must specify system to move ship to"  unless parent.is_a?(Cosmos::SolarSystem)
  
  # TODO may want to incorporate fuel into this at some point
  
  Manufactured::Registry.instance.safely_run {
    # update the entity's location
    entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))
  
    # if parents don't match, we are moving entity between systems
    if entity.parent.id != parent.id
      # if moving ship ensure it is within trigger distance of gate to new system and is not docked
      #   (TODO currently stations don't have this restriction though we may want to put others in place, or a transport delay / time)
      # TODO support skipping this check if user has sufficient privs (perhaps modify-manufactured_entities ?)
      if entity.is_a?(Manufactured::Ship)
        near_jg = !entity.solar_system.jump_gates.select { |jg| jg.endpoint.name == parent.name &&
                                                                (jg.location - entity.location) < jg.trigger_distance }.empty?
        raise Omega::OperationError, "Ship #{entity} not within triggering distance of a jump gate to #{parent}" unless near_jg
        raise Omega::OperationError, "Ship #{entity} is docked, cannot move" if entity.docked?
      end
  
      # simply set parent and location
      # TODO set new_location x, y, z to vicinity of reverse jump gate (eg gate to current system in destination system) if it exists
      entity.parent   = parent
      new_location.movement_strategy = Motel::MovementStrategies::Stopped.instance
      entity.location.update(new_location)
  
      # TODO add subscriptions to cosmos system to detect when ships jump in / out
  
      @@local_node.invoke_request('motel::update_location', entity.location)
      # TODO why do we remove callbacks? should we remove them all ? or leave them be?
      @@local_node.invoke_request('motel::remove_callbacks', entity.location.id, 'movement')
      @@local_node.invoke_request('motel::remove_callbacks', entity.location.id, 'rotation')
  
    # else move location within the system
    else
      # if moving ship, ensure it is not docked
      if entity.is_a?(Manufactured::Ship) && entity.docked?
        raise Omega::OperationError, "Ship #{entity} is docked, cannot move"
      end
  
      dx = new_location.x - entity.location.x
      dy = new_location.y - entity.location.y
      dz = new_location.z - entity.location.z
      distance = new_location - entity.location
  
      raise Omega::OperationError, "Ship or station #{entity} is already at location" if distance < 1
  
      # Move to location using a linear movement strategy.
      # If not oriented towards destination (or at least close enough), rotate first, then move
      linear =  Motel::MovementStrategies::Linear.new :direction_vector_x => dx/distance,
                                                      :direction_vector_y => dy/distance,
                                                      :direction_vector_z => dz/distance,
                                                      :speed => entity.movement_speed
      rot_a  = nil
      loc    = nil
  
      or_diff = entity.location.orientation_difference(*new_location.coordinates)
      entity.next_movement_strategy []
  
      if or_diff.all? { |od| od.abs < (Math::PI / 8) }
        entity.location.movement_strategy = linear
  
      else
        rot_a = or_diff[0].abs + or_diff[1].abs
        rotate = Motel::MovementStrategies::Rotate.new :dtheta => (or_diff[0] * entity.rotation_speed / rot_a),
                                                       :dphi   => (or_diff[1] * entity.rotation_speed / rot_a)
        entity.location.movement_strategy = rotate
        entity.next_movement_strategy linear
  
        # FIXME will overwrite any inprogress movement from a previous
        # move_entity command before it is used in on_movement below
        entity.distance_moved = distance
      end
  
      entity.next_movement_strategy Motel::MovementStrategies::Stopped.instance
      loc = entity.location
  
      @@local_node.invoke_request('motel::track_rotation', loc.id,    rot_a) unless rot_a.nil?
      @@local_node.invoke_request('motel::track_movement', loc.id, distance)
      @@local_node.invoke_request('motel::update_location', loc)
    end
  }
  
  entity
}

manufactured_follow_entity = proc { |id, target_id, distance|
  raise ArgumentError, "entity #{id} and target #{target_id} cannot be the same" if id == target_id
  
  entity = Manufactured::Registry.instance.find(:id => id).first
  target_entity = Manufactured::Registry.instance.find(:id => target_id).first
  
  raise Omega::DataNotFound, "manufactured entity specified by #{id} not found"  if entity.nil?
  raise Omega::DataNotFound, "manufactured entity specified by #{target_id} not found"  if target_entity.nil?
  
  raise ArgumentError, "distance must be an int / float > 0" if !distance.is_a?(Integer) && !distance.is_a?(Float) && distance <= 0
  
  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])
  Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{target_entity.id}"},
                                             {:privilege => 'view', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])
  
  # raise exception if entity or target is invalid
  raise ArgumentError, "Must specify ship to move"           unless entity.is_a?(Manufactured::Ship)
  raise ArgumentError, "Must specify ship to follow"         unless target_entity.is_a?(Manufactured::Ship)
  
  # atomically update the entities
  Manufactured::Registry.instance.safely_run {
    entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))
    target_entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', target_entity.location.id))
  
    # ensure entities are in the same system
    raise ArgumentError, "entity #{entity} must be in the same system as entity to follow #{target_entity}" if entity.location.parent.id != target_entity.location.parent.id
  
    # ensure entity isn't docked
    raise Omega::OperationError, "Ship #{entity} is docked, cannot move" if entity.docked?
  
    entity.location.movement_strategy =
      Motel::MovementStrategies::Follow.new :tracked_location_id => target_entity.location.id,
                                            :distance            => distance,
                                            :speed => entity.movement_speed
    @@local_node.invoke_request('motel::update_location', entity.location)
  }
  
  entity
}

manufactured_stop_entity = proc { |id|
  entity = Manufactured::Registry.instance.find(:id => id).first

  raise Omega::DataNotFound, "manufactured entity specified by #{id} not found"  if entity.nil?

  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])

  # raise exception if entity or parent is invalid
  raise ArgumentError, "Must specify ship or station to move" unless entity.is_a?(Manufactured::Ship) || entity.is_a?(Manufactured::Station)

  Manufactured::Registry.instance.safely_run {
    # update the entity's location
    entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))

    # set entity's movement strategy to stopped
    entity.location.movement_strategy =
      Motel::MovementStrategies::Stopped.instance
    @@local_node.invoke_request('motel::update_location', entity.location)
    # TODO remove_callbacks?
    # TODO stop mining / attack / other operations ?
  }

  entity
}


def dispatch_movement(dispatcher)
  dispatcher.handle 'manufactured::move_entity',
                      &manufactured_move_entity
  dispatcher.handle 'manufactured::follow_entity',
                      &manufactured_follow_entity
  dispatcher.handle 'manufactured::stop_entity',
                      &manufactured_stop_entity
end
