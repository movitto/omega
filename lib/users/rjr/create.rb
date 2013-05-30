# users::create_enttiy rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users::RJR

# Create new user in registry
create_user = proc { |user|
  # require create users unless on local node
  require_privilege :privilege => 'create',
                    :entity    => 'users' unless is_node?(::RJR::Nodes::Local)

  # ensure valid user is being created
  raise ValidationError, user unless user.is_a?(User)

  # secure all user passwords
  user.secure_password = true

  # mark permenant users as such
  user.permenant = true if Users::RJR.permenant_users.
                             find { |ui| user.id == ui }

  # store user
  added = Registry.instance << user
  raise OperationError, "#{user.id} already exists" if !added
  
  # create new user role for user, add it to user, assign it view/modify privs
  role = Role.new :id => "user_role_#{user.id}"
  @rjr_node.invoke('users::create_role', role)
  @rjr_node.invoke('users::add_role', user.id, role.id)
  @rjr_node.invoke('users::add_privilege', role.id, 'view',   "user-#{user.id}")
  @rjr_node.invoke('users::add_privilege', role.id, 'modify', "user-#{user.id}")

  # return user
  user
}

# Create new role in registry
create_role = proc { |role|
  # require create roles unless on local node
  require_privilege :privilege => 'create',
                    :entity    => 'roles' unless is_node?(::RJR::Nodes::Local)

  # ensure role is being created
  raise ValidationError, role unless role.is_a?(Role)

  # store role
  added = Users::Registry.instance << role
  raise OperationError, "#{role.id} already exists" if !added

  # return role
  role
}


CREATE_METHODS = { :create_user => create_user,
                   :create_role => create_role}

end # module Users::RJR

def dispatch_create(dispatcher)
  m = Users::RJR::CREATE_METHODS
  dispatcher.handle 'users::create_user', &m[:create_user]
  dispatcher.handle 'users::create_role', &m[:create_role]
end
