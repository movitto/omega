# manufactured::create_entity rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'

module Manufactured::RJR

# create specfieid entity in registry
create_entity = proc { |entity|
  require_privilege(:registry  => user_registry,
                    :privilege => 'create',
                    :entity    => 'manufactured_entities')
  
  raise ArgumentError,
    entity unless Registry::VALID_TYPES.include?(entityc.lass)
  
  # swap out the parent w/ the one stored in the cosmos registry
  parent = node.invoke('cosmos::get_entity', 'with_id', entity.system_id)
  raise DataNotFound, entity.system_id if parent.nil?
  entity.parent = parent

  # swap out location w/ the one stored in motel
  entity.location = node.invoke('motel::create_location', entity.location)
  entity.location.parent = entity.parent.location
  
  # grab user who is being set as entity owner
  user = node.invoke('users::get_entity', 'with_id', entity.user_id)
  raise DataNotFound, entity.user_id if user.nil?
  
###
  # modify base entity attributes from user attributes
  pli = Users::Attributes::PilotLevel.id
  oli = Users::Attributes::OffenseLevel.id
  dli = Users::Attributes::DefenseLevel.id
  mli = Users::Attributes::MiningLevel.id
  entity.movement_speed   +=
    (user.attribute(pli).level / 20) if user.has_attribute?(pli)
  entity.damage_dealt     +=
    (user.attribute(oli).level / 10) if user.has_attribute?(oli)
  entity.max_shield_level +=
    (user.attribute(dli).level / 10) if user.has_attribute?(dli)
  entity.mining_quantity  +=
    (user.attribute(mli).level / 10) if user.has_attribute?(mli)
  # adjust_attribute entity, :mining_quantity,
  #    user.attribute(MiningLevel).level / 10 if user.has_attribute?(MiningLevel)
  
  
  # XXX hack - give new stations enough resources
  # to construct a preliminary helper
  entity.resources['metal-steel'] = 100 if entity.is_a?(Manufactured::Station)
  
  # TODO ensue user has attribute enabling them to create entity
  # of the specified type
  
  # Ensure user can create another entity
  # FIXME needs to be run atomically during entity being added to registry
  n = registry.entities { |e| e.user_id == entity.user_id }.size
  can_create = node.invoke('users::has_attribute?', entity.user_id,
                           Users::Attributes::EntityManagementLevel.id, n + 1)
  raise PermissionError, "#{entity.user_id} at max entities" unless can_create
  #require_attribute entity.user_id, EntityManagementLevel, n + 1
###

  # store entity, throw error if not added
  added = registry << entity
  raise OperationError, "#{added} not create" unless added
  # FIXME need to delete the location from motel is entity isn't added
  
  # add permissions to view & modify entity to owner
  user_role = "user_role_#{user.id}"
  [["view",   "manufactured_entity-#{entity.id}"],
   ['modify', "manufactured_entity-#{entity.id}"],
   ['view',   "location-#{entity.location.id}"]].each { |p,e|
     node.invoke('users::add_privilege', user_role, p, e)
   }
  
  # return entity
  entity
}

# Construct entity via station.
# Entity will be constructed immediately but will not be available for use
# until it is processed by the registry construction cycle
construct_entity = proc { |manufacturer_id, args|
  station = registry.entity &with_id(manufacturer_id)
  raise DataNotFound, manufacturer_id if station.nil? || !station.is_a?(Station)

  require_privilege(:registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "manufactured_entity-#{station.id}"},
     {:privilege => 'modify', :entity => 'manufactured_entities'}],

# FIXME filter params able to be set by the user

  # auto-set additional params
  args[:solar_system] = station.solar_system
  args[:user_id] = current_user(:registry => user_registry).id
  # TODO change to station's owner ?

  # TODO also check construction related user attributes
  #  (construction class, parallel construction)

  entity = nil

  completed_callback =
    Callback.new(:construction_complete, :endpoint => node.message_headers['source_node']){ |*args|
      station.notification_callbacks.delete(completed_callback)

      # FIXME how to handle if create_entity fails for whatever reason?
      node.invoke_request('manufactured::create_entity', entity)
    }

  # FIXME needs to be atomic w/ construct & update
  raise OperationError,
          "#{station} cant construct #{args}" unless station.can_construct?(args)

  # track delayed station construction
  station.callbacks << completed_callback

  # create the entity and return it
  entity = station.construct args

  # TODO update etation in registry

  raise OperationError, "#{station} cant construct #{args}" if entity.nil?

  # schedule construction / placement in system in construction cycle
  registry << Construction.new :station => station, :entity => entity

  # Return station and constructed entity
  [station, entity]
}

CREATE_METHODS = { :create_entity => create_entity,
                   :construct_entity => construct_entity }
end

def dispatch_manufactured_rjr_create(dispatcher)
  m = MANUFACTURED::RJR::CREATE_METHODS
  dispatcher.handle 'manufactured::create',    &m[:create_entity]
  dispatcher.handle 'manufactured::construct', &m[:construct_entity]
end
