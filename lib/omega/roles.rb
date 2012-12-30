# omega roles data
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/user'
require 'rjr/local_node'

module Omega

# The Roles module provides mechanisms to assign privileges to users
# depending on roles assigned to them. A role is a named list of privileges
# some of which may be applied to entities or entity types.
module Roles

PRIVILEGE_VIEW     = 'view'
PRIVILEGE_CREATE  = 'create'
PRIVILEGE_MODIFY  = 'modify'
PRIVILEGE_DELETE = 'delete'

PRIVILEGES        = [PRIVILEGE_VIEW, PRIVILEGE_CREATE, PRIVILEGE_MODIFY, PRIVILEGE_DELETE]

ENTITIES_LOCATIONS    = 'locations'
ENTITIES_COSMOS       = 'cosmos_entities'
ENTITIES_MANUFACTURED = 'manufactured_entities'
ENTITIES_USERS        = 'users_entities'
ENTITIES_USER         = 'users'
ENTITIES_PRIVILEGES   = 'privileges'

ENTITY_LOCATION     = "location-"
ENTITY_COSMOS       = "cosmos_entity-"
ENTITY_MANUFACTURED = "manufacture_entity-"
ENTITY_USERS        = "users_entity-"
ENTITY_USER         = "user-"

ENTITIES            = [ENTITIES_LOCATIONS, ENTITIES_COSMOS, ENTITIES_MANUFACTURED, ENTITIES_USERS, ENTITIES_USER, ENTITIES_PRIVILEGES]
ENTITYS             = [ENTITY_LOCATION,    ENTITY_COSMOS,   ENTITY_MANUFACTURED,   ENTITY_USERS,   ENTITY_USER]

# Master dictionary of role names to lists of privileges and entities that they correspond to
ROLES = { :superadmin => PRIVILEGES.product(ENTITIES),
          :remote_location_manager => [[PRIVILEGE_VIEW, ENTITIES_LOCATIONS], [PRIVILEGE_CREATE, ENTITIES_LOCATIONS], [PRIVILEGE_MODIFY, ENTITIES_LOCATIONS]],
          :remote_cosmos_manager   => [[PRIVILEGE_VIEW, ENTITIES_COSMOS],    [PRIVILEGE_CREATE, ENTITIES_COSMOS],    [PRIVILEGE_MODIFY, ENTITIES_COSMOS]],
          :regular_user            => [[PRIVILEGE_VIEW, ENTITIES_COSMOS],    [PRIVILEGE_CREATE, ENTITIES_MANUFACTURED], [PRIVILEGE_VIEW,   ENTITIES_MANUFACTURED], [PRIVILEGE_VIEW, ENTITIES_LOCATIONS]], # TODO doesn't take fog of war into account
          :anonymous_user          => [[PRIVILEGE_VIEW, ENTITIES_COSMOS],    [PRIVILEGE_VIEW,   ENTITIES_MANUFACTURED], [PRIVILEGE_VIEW, ENTITIES_LOCATIONS]]} # TODO pretty lax anonymous user


end # module Roles
end # module Omega
