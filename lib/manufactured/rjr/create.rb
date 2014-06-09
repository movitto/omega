# manufactured::create_entity rjr definitions
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

  # TODO split into seperate modules

require 'manufactured/rjr/init'
require 'manufactured/rjr/create/attributes'
require 'manufactured/rjr/validate/attributes'

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

    # run user attribute validation ahead of time
    #  (not required but useful error to raise here
    validate_user_attributes(registry.entities, entity)

    ###################### create/modify entity & supporting data

    # modify base ship attributes from user attributes
    set_entity_attributes(entity, user)

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

  CREATE_METHODS = {:create_entity => create_entity}
end

def dispatch_manufactured_rjr_create(dispatcher)
  m = Manufactured::RJR::CREATE_METHODS
  dispatcher.handle 'manufactured::create_entity', &m[:create_entity]
end
