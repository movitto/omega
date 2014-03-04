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

# helper to validate use attributes upon entity creation
def validate_user_attributes(entities, entity)
  # only applies to ships / stations
  # TODO skip this requirement if entity belongs to a npc user
  if entity.is_a?(Ship) || entity.is_a?(Station)
    # retrieve alive entities belonging to user
    n = entities.count { |e| (e.is_a?(Ship) || e.is_a?(Station)) &&
                              e.user_id == entity.user_id        &&
                            (!e.is_a?(Ship) || e.alive?)            }

    require_attribute :node => Manufactured::RJR.node,
      :user_id => entity.user_id,
      :attribute_id => Users::Attributes::EntityManagementLevel.id,
      :level => n+1

    # TODO also ensure user has attribute enabling them to
    # create entity of the specified type
  end
end

# callback to validate user attributes upon entity creation
#
# Defined here as it requires access to node, added to registry below
validate_user_attributes = proc { |entities, entity|
  validated = true
  begin
    @manu_validator ||= Object.new.extend(Manufactured::RJR) # XXX
    @manu_validator.validate_user_attributes(entities, entity)
  rescue ValidationError => e
    validated = false
  end
  validated
}

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

  # run user attribute validation ahead of time
  #  (not required but useful error to raise here
  validate_user_attributes(registry.entities, entity)

  ###################### create/modify entity & supporting data

  # modify base ship attributes from user attributes
  # entity attribute |          user attribute           | scale
  [[:movement_speed,   Users::Attributes::PilotLevel.id,   20],
   [:damage_dealt,     Users::Attributes::OffenseLevel.id, 10],
   [:max_shield_level, Users::Attributes::DefenseLevel.id, 10],
   [:mining_quantity,  Users::Attributes::MiningLevel.id,  10]].each { |p,a,l|
     entity.send("#{p}+=".intern,
                 user.attribute(a).level / l) if user.has_attribute?(a)
   } if entity.is_a?(Ship)

  # give new stations enough resources to construct a preliminary helper
  entity.add_resource \
    Cosmos::Resource.new(:id => Motel.gen_uuid,
                         :material_id => 'metal-steel',
                         :quantity => 100) if entity.is_a?(Station)

  # create location in motel, swap it in locally
  # TODO ensure ms is stopped or validate ms
  entity.location.id = entity.id
  entity.location =
    begin node.invoke('motel::create_location', entity.location)
    rescue Exception => e
      raise OperationError, "#{entity.location} not created"
    end
  entity.location.parent = entity.parent.location

  # store entity, throw error if not added
  added = registry << entity
  unless added
    # delete the location from motel if entity isn't added
    node.invoke('motel::delete_location', entity.location.id)

    # raise err
    raise OperationError, "#{entity} not created"
  end

  # add permissions to view & modify entity to owner
  user_role = "user_role_#{user.id}"
  owner_permissions_for(entity).each { |p,e|
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

  # invoke update operations on registry station
  entity =
    registry.safe_exec { |entities|
      # grab registry station
      rstation = entities.find &with_id(station.id)

      # actually constructs entity and returns it
      #  (atomically checks can_construct? and removes resources)
      rstation.construct args
    }

  # ensure entity was created
  raise OperationError,
    "#{station} can't construct #{args}" if entity.nil?

  # add construction command to registry to be run in loop cycle
  registry << Commands::Construction.new(:station => station, :entity => entity)

  # TODO update station returned or return rstation

  # Return station and constructed entity
  [station, entity]
}

CREATE_METHODS = { :validate_user_attributes  => validate_user_attributes,
                   :create_entity    => create_entity,
                   :construct_entity => construct_entity }
end

def dispatch_manufactured_rjr_create(dispatcher)
  m = Manufactured::RJR::CREATE_METHODS
  dispatcher.handle 'manufactured::create_entity',    &m[:create_entity]
  dispatcher.handle 'manufactured::construct_entity', &m[:construct_entity]

  # register entity validation method w/ registry
  unless Manufactured::RJR.registry.validation_methods.
                           include?(m[:validate_user_attributes])
    Manufactured::RJR.registry.validation_callback &m[:validate_user_attributes]
  end
end
