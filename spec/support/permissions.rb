# Omega Spec Permissions Helper
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# Helper method to temporarily disable permission system
def disable_permissions
  o = Users::Registry.user_perms_enabled
  Users::Registry.user_perms_enabled = false
  r = yield
  Users::Registry.user_perms_enabled = o
  r
end

# Helper to reload a superadmin user for client use.
#
# superadmin role entails alot of privileges and
# is used often so continuously recreating w/ add_role
# is slow, this helper speeds things up (~70% faster on avg)
def reload_super_admin
  # XXX global var
  if $sa.nil?
    $sa = create(:user)
    role_id = "user_role_#{$sa.id}"
    add_role role_id, :superadmin
    $sa_role = Users::RJR.registry.entity { |e| e.is_a?(Users::Role) && e.id == role_id }
  else
    Users::RJR.registry << $sa_role
    $sa.roles = [$sa_role]
    Users::RJR.registry << $sa
  end

  $sa
end

# Extend session to include a method that forces timeout
module Users
class Session
  def expire!
    @refreshed_time = Time.now - Session::SESSION_EXPIRATION - 100
  end
end
end
