# users::create_entity rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

users_create_entity = proc { |entity|
  unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
    Users::Registry.require_privilege(:privilege => 'create', :entity => 'users_entities',
                                      :session   => @headers['session_id'])
  end

  raise ArgumentError, "entity must be one of #{Users::Registry::VALID_TYPES}" unless Users::Registry::VALID_TYPES.include?(entity.class)
  raise ArgumentError, "entity id #{entity.id} already taken" unless Users::Registry.instance.find(:type => entity.class.to_s, :id => entity.id).empty?

  entity.secure_password = true if entity.is_a? Users::User

  Users::Registry.instance.create entity

  if entity.is_a?(Users::User) || entity.is_a?(Users::Alliance)
    owner = nil

    if entity.is_a?(Users::User)
      owner = entity

      # create new user role for user
      role = Users::Role.new :id => "user_role_#{entity.id}"
      @@local_node.invoke_request('users::create_entity', role)
      @@local_node.invoke_request('users::add_role', entity.id, role.id)

      # mark permenant users as such
      if Users::RJRAdapter.permenant_users.find { |un| entity.id == un }
        entity.permenant = true
      end

    else
      owner = entity.members.first
    end

    # add permissions to view & modify entity to owner
    unless owner.nil?
      role_id = "user_role_#{owner.id}"
      @@local_node.invoke_request('users::add_privilege', role_id, 'view',   "users_entity-#{entity.id}")
      @@local_node.invoke_request('users::add_privilege', role_id, 'view',   "user-#{entity.id}")
      @@local_node.invoke_request('users::add_privilege', role_id, 'modify', "users_entity-#{entity.id}")
      @@local_node.invoke_request('users::add_privilege', role_id, 'modify', "user-#{entity.id}")
    end
  end

  entity
}

def dispatch_get(dispatcher)
  dispatcher.handle 'users::create_entity', &users_create_entity
end
