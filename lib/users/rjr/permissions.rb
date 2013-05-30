# users::add_role, users::add_privilege rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users::RJR

# Add new role to user
add_role = proc { |user_id, role_id|
  # require modify roles unless on the local node
  require_privilege :privilege => 'modify',
                    :entity    => 'roles' unless is_node?(::RJR::Nodes::Local)

  # retrieve the user and role from the registry
  user = Registry.instance.entities { |e| e.id == user_id }.first
  role = Registry.instance.entities { |e| e.id == role_id }.first

  # ensure user/role were found
  raise Omega::DataNotFound, user_id if user.nil?
  raise Omega::DataNotFound, role_id if role.nil?

  # safely execute operation
  # XXX role is a reference to registry role,
  # relies on registry :updated hook to correctly reference role
  user.add_role role
  Registry.instance.update(user, &with_id(user.id))

  # return nil
  nil
}

# Add new privilege (on optional entity) to user
add_privilege = proc { |*args|
  # return modify roles unless on the local node
  require_privilege :privilege => 'modify',
                    :entity    => 'roles' unless is_node?(::RJR::Nodes::Local)

  # retrieve args (entity_id is optional)
  role_id      = args[0]
  privilege_id = args[1]
  entity_id    = args.size > 2 ? args[2] : nil

  # retrieve role from registry
  role = Registry.instance.entities { |e| e.id == role_id }.first

  # ensure role was found
  raise Omega::DataNotFound, role_id if role.nil?

  # safely execute operation
  role.add_privilege privilege_id, entity_id
  Registry.instance.update(role, &with_id(role.id))

  # return nil
  nil
}

PERMISSION_METHODS = { :add_role => add_role,
                       :add_privilege => add_privilege }

end # module Users::RJR

def dispatch_permissions(dispatcher)
  m = Users::RJR::PERMISSION_METHODS

  dispatcher.handle 'users::add_role', &m[:add_role]
  #dispatcher.handle 'users::remove_role', 'TODO'

  dispatcher.handle 'users::add_privilege', &m[:add_privilege]
  #dispatcher.handle 'users::remove_privilege', 'TODO'
end
