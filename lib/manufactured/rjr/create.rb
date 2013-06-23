# manufactured::create_entity and
# manufacuted::construct_entity rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'
require 'manufactured/commands/construction'
require 'users/attributes/interact'
require 'users/attributes/own'

module Manufactured::RJR

# create specified entity in registry
create_entity = proc { |entity|

  ###################### validate data

  # require create-manufactured_entities
  require_privilege :registry  => user_registry,
                    :privilege => 'create',
                    :entity    => 'manufactured_entities'
  
  # validate type of entity
  raise ValidationError,
    entity unless Registry::VALID_TYPES.include?(entity.class)
  
  # swap out the parent w/ the one stored in the cosmos registry
  parent =
    begin node.invoke('cosmos::get_entity', 'with_id', entity.system_id)
    rescue Exception => e ; raise DataNotFound, entity.system_id end
  entity.parent = parent

  # grab user who is being set as entity owner
  user =
    begin node.invoke('users::get_entity', 'with_id', entity.user_id)
    rescue Exception => e ; raise DataNotFound, entity.user_id if user.nil? end

  # Ensure user can create another entity
  # FIXME needs to be run atomically with entity being added to registry
  #       (or move to registry validation?)
  # TODO also ensure user has attribute enabling them to
  # create entity of the specified type
  # TODO exclude entities w/ hp == 0
  n = registry.entities { |e|
    Registry::VALID_TYPES.include?(e.class) &&
                e.user_id == entity.user_id    }.size
  require_attribute :node => node,
    :user_id => entity.user_id,
    :attribute_id => Users::Attributes::EntityManagementLevel.id,
    :level => n+1

  ###################### create/modify entity & supporting data 

  # modify base entity attributes from user attributes
  # entity attribute |          user attribute           | scale 
  [[:movement_speed,   Users::Attributes::PilotLevel.id,   20],
   [:damage_dealt,     Users::Attributes::OffenseLevel.id, 10],
   [:max_shield_level, Users::Attributes::DefenseLevel.id, 10],
   [:mining_quantity,  Users::Attributes::MiningLevel.id,  10]].each { |p,a,l|
     entity.send("#{p}+=".intern,
                 user.attribute(a).level / l) if user.has_attribute?(a)
   }

  # give new stations enough resources to construct a preliminary helper
  entity.add_resource \
    Cosmos::Resource.new(:id       => 'metal-steel',
                         :quantity => 100) if entity.is_a?(Station)
  
  # create location in motel, swap it in locally
  entity.location.id = entity.id
  entity.location =
    begin node.invoke('motel::create_location', entity.location)
    rescue Exception => e
      raise OperationError, "#{entity.location} not created"
    end
  entity.location.parent = entity.parent.location
  
  # store entity, throw error if not added
  # FIXME need to delete the location from motel if entity isn't added
  added = registry << entity
  raise OperationError, "#{entity} not created" unless added
  
  # add permissions to view & modify entity to owner
  user_role = "user_role_#{user.id}"
  [["view",   "manufactured_entity-#{entity.id}"],
   ['modify', "manufactured_entity-#{entity.id}"],
   ['view',   "location-#{entity.location.id}"]].each { |p,e|
     node.invoke('users::add_privilege', user_role, p, e)
   }
  
  ############################ return entity
  entity
}

# Construct entity via station.
# Entity will be constructed immediately but will not be available for use
# until it is processed by the registry construction cycle
construct_entity = proc { |manufacturer_id, *args|

  ###################### validate construction

  # retrieve manufacturing station
  station = registry.entity &with_id(manufacturer_id)
  raise DataNotFound,
    manufacturer_id if station.nil? || !station.is_a?(Station)

  # update station's location & system
  station.location =
    node.invoke('motel::get_location', 'with_id', station.location.id)
  station.solar_system =
    node.invoke('cosmos::get_entity', 'with_location', station.location.parent_id)

  # ensure user can modify station
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "manufactured_entity-#{station.id}"},
     {:privilege => 'modify', :entity => 'manufactured_entities'}]

  # filter entity params able to be set by the user
  # only allow user to specify id, type, and entity_type
  # everything else is generated serverside
  args = filter_properties Hash[*args], :allow => [:id, :type, :entity_type]

  # auto-set additional params on entity to create.
  # we can also set user_id to station's owner or
  # allow it to be passed in as an arg if we want
  args[:solar_system] = station.solar_system
  args[:user_id]      = current_user(:registry => user_registry).id

  # verify station can construct entity
  # TODO also check construction related user attributes
  #  (construction class, parallel construction)
  raise OperationError,
    "#{station} can't construct #{args}" unless station.can_construct?(args)

  ###################### create entity & supporting data 
  entity = nil

  # create new callback to be run on construction completion
  cb = Omega::Server::Callback.new
  cb.endpoint_id = @rjr_headers['source_node']
  cb.rjr_event   = 'manufactured::event_occurred'
  cb.event_type  = :construction_complete
  cb.handler =
    proc { |args|
      registry.safe_exec { |entities|
        # grab registry station
        rstation = entities.find &with_id(station.id)

        # delete the callback
        rstation.callbacks.delete(cb)
      }

      # create the entity in registry
      # FIXME how to handle if call to create_entity fails?
      node.invoke('manufactured::create_entity', entity)
    }

  # invoke update operations on registry station
  entity = 
    registry.safe_exec { |entities|
      # grab registry station
      rstation = entities.find &with_id(station.id)

      # track entity construction via station callbacks
      rstation.callbacks << cb

      # actually constructs entity and returns it
      #  (atomically checks can_construct? and removes resources)
      rstation.construct args
    }

  # ensure entity was created
  raise OperationError,
    "#{station} can't construct #{args}" if entity.nil?
  # add construction command to registry to be run in loop cycle
  registry << Commands::Construction.new(:station => station, :entity => entity)

  # Return station and constructed entity
  [station, entity]
}

CREATE_METHODS = { :create_entity => create_entity,
                   :construct_entity => construct_entity }
end

def dispatch_manufactured_rjr_create(dispatcher)
  m = Manufactured::RJR::CREATE_METHODS
  dispatcher.handle 'manufactured::create_entity',    &m[:create_entity]
  dispatcher.handle 'manufactured::construct_entity', &m[:construct_entity]
end
