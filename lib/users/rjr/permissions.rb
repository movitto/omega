# users::add_role, users::add_privilege rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users::RJR

# Add new role to user
add_role = proc { |user_id, role_id|
  # require modify roles unless on the local node
  require_privilege :registry  => registry,
                    :privilege => 'modify',
                    :entity    => 'roles' unless is_node?(::RJR::Nodes::Local)

  # retrieve the user and role from the registry
  user = registry.entity &with_id(user_id)
  role = registry.entity &with_id(role_id)

  # ensure user/role were found
  raise Omega::DataNotFound, user_id if user.nil?
  raise Omega::DataNotFound, role_id if role.nil?

  # safely execute operation
  # XXX role is a copy of registry role,
  # relies on registry :updated hook to correctly reference role
  user.add_role role
  registry.update user, &with_id(user.id)

  # return nil
  nil
}

# Remove a role from a user
remove_role = proc { |user_id, role_id|
  # require modify roles unless on the local node
  require_privilege :registry  => registry,
                    :privilege => 'modify',
                    :entity    => 'roles' unless is_node?(::RJR::Nodes::Local)

  # retrieve the user and role from the registry
  user = registry.entity &with_id(user_id)
  role = registry.entity &with_id(role_id)

  # ensure user/role were found
  raise Omega::DataNotFound, user_id if user.nil?
  raise Omega::DataNotFound, role_id if role.nil?
  raise ArgumentError, "user does not have role" unless user.has_role?(role.id)

  # remove role from user, update in registry
  user.remove_role(role.id)
  registry.update user, &with_id(user.id)

  # return nil
  nil
}

# Add new privilege (on optional entity) to role
add_privilege = proc { |*args|
  # return modify roles unless on the local node
  require_privilege :registry  => registry,
                    :privilege => 'modify',
                    :entity    => 'roles' unless is_node?(::RJR::Nodes::Local)

  # retrieve args (entity_id is optional)
  role_id      = args[0]
  privilege_id = args[1]
  entity_id    = args.size > 2 ? args[2] : nil

  # retrieve role from registry
  role = registry.entity &with_id(role_id)

  # ensure role was found
  raise Omega::DataNotFound, role_id if role.nil?

  # safely execute operation
  role.add_privilege privilege_id, entity_id
  registry.update role, &with_id(role.id)

  # return nil
  nil
}

# Remove a privilege from a role
remove_privilege = proc { |*args|
  # return modify roles unless on the local node
  require_privilege :registry  => registry,
                    :privilege => 'modify',
                    :entity    => 'roles' unless is_node?(::RJR::Nodes::Local)

  # retrieve args (entity_id is optional)
  role_id      = args[0]
  privilege_id = args[1]
  entity_id    = args.size > 2 ? args[2] : nil

  # retrieve role from registry
  role = registry.entity &with_id(role_id)

  # ensure role was found and has privilege
  raise Omega::DataNotFound, role_id if role.nil?
  raise ArgumentError,
    "role does not have privilege" unless role.has_privilege_on?(privilege_id,
                                                                    entity_id)

  # remove privilege from role, update in registry
  role.remove_privilege(privilege_id, entity_id)
  registry.update role, &with_id(role.id)

  # return nil
  nil
}

PERMISSION_METHODS = { :add_role => add_role,
                       :remove_role => remove_role,
                       :add_privilege => add_privilege,
                       :remove_privilege => remove_privilege}

end # module Users::RJR

def dispatch_users_rjr_permissions(dispatcher)
  m = Users::RJR::PERMISSION_METHODS

  dispatcher.handle 'users::add_role', &m[:add_role]
  dispatcher.handle 'users::remove_role', &m[:remove_role]

  dispatcher.handle 'users::add_privilege', &m[:add_privilege]
  dispatcher.handle 'users::remove_privilege', &m[:remove_privilege]
end
