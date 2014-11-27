# Omega Spec Client Helper
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/roles'

# Helper to add privilege on entity (optional)
# to the specified role
def add_privilege(role_id, priv_id, entity_id=nil)
  # change node type to local here to ensure this goes through
  o = @n.node_type
  @n.node_type = RJR::Nodes::Local::RJR_NODE_TYPE
  r = @n.invoke 'users::add_privilege', role_id, priv_id, entity_id
  @n.node_type = o
  r
end

# Helper to add omega role to user role
def add_role(user_role, omega_role)
  # change node type to local here to ensure this goes through
  o = @n.node_type
  @n.node_type = RJR::Nodes::Local::RJR_NODE_TYPE
  r = []
  Omega::Roles::ROLES[omega_role].each { |p,e|
    r << @n.invoke('users::add_privilege', user_role, p, e)
  }
  @n.node_type = o
  r
end

# Helper to add attribute to user
def add_attribute(user_id, attribute_id, level)
  disable_permissions {
    @n.invoke 'users::update_attribute', user_id, attribute_id, level
  }
end
