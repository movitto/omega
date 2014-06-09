# manufacuted::construct_entity rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'
require 'manufactured/commands/construction'

module Manufactured::RJR
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

  CONSTRUCT_METHODS = {:construct_entity => construct_entity}
end # module Manufactured::RJR

def dispatch_manufactured_rjr_construct(dispatcher)
  m = Manufactured::RJR::CONSTRUCT_METHODS

  dispatcher.handle 'manufactured::construct_entity', &m[:construct_entity]
end
