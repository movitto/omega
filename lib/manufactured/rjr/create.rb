# manufactured::create_entity rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

manufactured_create_entity = proc { |entity|
  Users::Registry.require_privilege(:privilege => 'create', :entity => 'manufactured_entities',
                                    :session   => @headers['session_id'])
  
  valid_types = Manufactured::Registry.instance.entity_types
  raise ArgumentError, "Invalid #{entity.class} entity specified, must be one of #{valid_types.inspect}" unless valid_types.include?(entity.class)
  
  # swap out the parent w/ the one stored in the cosmos registry
  if entity.parent
    parent = @@local_node.invoke_request('cosmos::get_entity', 'of_type', :solarsystem, 'with_name', entity.parent.name)
    raise Omega::DataNotFound, "parent system specified by #{entity.parent.name} not found" if parent.nil?
    # TODO parent.can_add?(entity)
    Manufactured::Registry.instance.safely_run {
      entity.parent = parent
    }
  end
  
  # ensure entity id not already taken
  rentity = Manufactured::Registry.instance.find(:id => entity.id,
                                                 :include_graveyard => true).first
  raise ArgumentError, "#{entity.class} with id #{entity.id} already taken" unless rentity.nil?
  
  # grab user who is being set as entity owner
  user = @@local_node.invoke_request('users::get_entity', 'with_id', entity.user_id)
  raise Omega::DataNotFound, "user specified by #{entity.user_id} not found" if user.nil?
  
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
  
  
  # XXX hack - give new stations enough resources
  # to construct a preliminary helper
  entity.resources['metal-steel'] = 100 if entity.is_a?(Manufactured::Station)
  
  # TODO ensue user has attribute enabling them to create entity
  # of the specified type
  
  # Ensure user can create another entity
  # FIXME needs to be run atomically before/during entity being added to registry
  # ensure user can own another entity
  n = Manufactured::Registry.instance.find(:user_id => entity.user_id).size
  can_create = @@local_node.invoke_request('users::has_attribute?',
                                                    entity.user_id,
                       Users::Attributes::EntityManagementLevel.id,
                                                              n + 1)
  raise Omega::PermissionError, "User #{entity.user_id} cannot own any more entities (max #{n})" unless can_create
  
  eloc = nil
  
  unless entity.location.nil?
    # needs to happen b4 create_location so motel sets up heirarchy correctly
    entity.location.parent_id = entity.parent.location.id if entity.parent
    # creation of location needs to happen before creation of entity
    eloc = @@local_node.invoke_request('motel::create_location', entity.location)
    # needs to happen after create_location as parent won't be sent in the result
    entity.location.parent    = entity.parent.location if entity.parent
  end
  
  rentity = Manufactured::Registry.instance.create(entity) { |e|
    e.location = eloc
  }
  
  #if rentity.nil? && !eloc.nil? # FIXME need to delete the location from motel
  
  # add permissions to view & modify entity to owner
  @@local_node.invoke_request('users::add_privilege', "user_role_#{user.id}", 'view',   "manufactured_entity-#{entity.id}" )
  @@local_node.invoke_request('users::add_privilege', "user_role_#{user.id}", 'modify', "manufactured_entity-#{entity.id}" )
  @@local_node.invoke_request('users::add_privilege', "user_role_#{user.id}", 'view',   "location-#{entity.location.id}" )
  
  rentity
}

# entity will be constructed immediately but will not be available for use
# until it is processed by the registry construction cycle
manufactured_construct_entity = proc { |manufacturer_id, entity_type, *args|
  station = Manufactured::Registry.instance.find(:type => "Manufactured::Station", :id => manufacturer_id).first
  raise Omega::DataNotFound, "station specified by #{manufacturer_id} not found" if station.nil?

  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{station.id}"},
                                             {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])

  # simply convert remaining args into key /
  # value pairs to pass into construct
  argsh = Hash[*args]

  # remove params which should not be set by the user
  # location is validated / modified in station.construct so no need to manipulate here
  ['solar_system','user_id', 'hp',
   'mining', 'attacking', 'cargo_capacity', 'resources', 'notifications',
   'current_shield_level', 'docked_at', 'size', 'speed'].each { |i| # set docked at to station?
    argsh.delete(i)
  }

  # auto-set additional params
  argsh[:entity_type] = entity_type
  argsh[:solar_system] = station.solar_system
  argsh[:user_id] = Users::Registry.current_user(:session => @headers['session_id']).id # TODO set permissions on entity? # TODO change to station's owner ?

  # TODO also check construction related user attributes (construction class, parallel construction)

  entity = nil

  completed_callback =
    Callback.new(:construction_complete, :endpoint => @@local_node.message_headers['source_node']){ |*args|
      # XXX unsafely run hack needed as callback will be invoked within
      # registry lock and create_entity will also attempt to obtain lock
      Manufactured::Registry.instance.unsafely_run {
        station.notification_callbacks.delete(completed_callback)

        # FIXME how to handle if create_entity fails for whatever reason?
        @@local_node.invoke_request('manufactured::create_entity', entity)
      }
    }

  Manufactured::Registry.instance.safely_run {
    station.clear_errors :of_type => :construction
    unless station.can_construct?(argsh)
      raise ArgumentError,
            "station specified by #{station} "\
            "cannot construct entity with args #{args.inspect} "\
            "due to errors: #{station.errors[:construction]} "
    end

    # track delayed station construction
    station.notification_callbacks << completed_callback

    # create the entity and return it
    entity = station.construct argsh
  }

  raise ArgumentError, "could not construct #{entity_type} at #{station} with args #{args.inspect}" if entity.nil?

  # schedule construction / placement in system in construction cycle
  Manufactured::Registry.instance.schedule_construction :station => station, :entity => entity

  # Return station and constructed entity
  [station, entity]
}

def dispatch_create(dispatcher)
  dispatcher.handle 'manufactured::create',    &manufactured_create_entity
  dispatcher.handle 'manufactured::construct', &manufactured_construct_entity
end
