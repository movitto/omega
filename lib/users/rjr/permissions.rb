# users::add_role, users::add_privilege' rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

users_add_role = proc { |user_id, role_id|
  unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
    Users::Registry.require_privilege(:privilege => 'modify', :entity => 'users_entities',
                                      :session   => @headers['session_id'])
  end

  user = Users::Registry.instance.find(:id => user_id, :type => "Users::User").first
  role = Users::Registry.instance.find(:id => role_id, :type => "Users::Role").first
  raise Omega::DataNotFound, "user specified by id #{user_id} not found" if user.nil?
  raise Omega::DataNotFound, "role specified by id #{role_id} not found" if role.nil?
  Users::Registry.instance.safely_run {
    user.add_role role
  }
  nil
}

users_add_privilege = proc { |*args|
  unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
    Users::Registry.require_privilege(:privilege => 'modify', :entity => 'users_entities',
                                      :session   => @headers['session_id'])
  end

  role_id      = args[0]
  privilege_id = args[1]
  entity_id    = args.size > 2 ? args[2] : nil

  role = Users::Registry.instance.find(:id => role_id, :type => "Users::Role").first
  raise Omega::DataNotFound, "role specified by id #{role_id} not found" if role.nil?
  Users::Registry.instance.safely_run {
    role.add_privilege privilege_id, entity_id
  }
  nil
}

def dispatch_permissions(dispatcher)
  dispatcher.handle 'users::add_role', &users_add_role
  #dispatcher.handle 'users::remove_role', 'TODO'

  dispatcher.handle 'users::add_privilege', &users_add_privilege
  #dispatcher.handle 'users::remove_privilege', 'TODO'
end
