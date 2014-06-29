# Users User HasRoles Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'users/role'

module Users

# Mixed into User, provides role capabilities
module HasRoles
  # [Array<Users::Role>] array of roles the user has
  attr_accessor :roles

  # Initialize default roles / roles from arguments
  def roles_from_args(args)
    attr_from_args args, :roles => roles
  end

  # Update roles from specified user
  def update_roles(user)
    @roles = user.roles unless user.roles.nil?
  end

  # Clear the roles the user has
  def clear_roles
    @roles ||= []
    @roles.clear
  end

  # Adds the roles specified by its arguments to the user
  #
  # @param [Users::Role] role role to add to user
  def add_role(role)
    @roles ||= []
    @roles << role unless role.nil? ||
                          has_role?(role.id)
  end

  # Return bool indicating if the user has the specified role
  #
  # @param [String] role_id id of the role to look for
  # @return bool indicating if the user has the role
  def has_role?(role_id)
    @roles ||= []
    @roles.any? { |r| r.id == role_id }
  end

  # Remove the specified role from the user
  def remove_role(role_id)
    return unless has_role?(role_id)
    @roles.reject! { |r| r.id == role_id }
  end

  # Return a list of privileges which the roles assigned to
  # the user provides
  #
  # @return [Array<Users::Privilege>] array of privileges the user has
  def privileges
    @roles ||= []
    @roles.collect { |r| r.privileges }.flatten.uniq
  end

  # Returns boolean indicating if the user has the specified privilege on the specified entity
  #
  # @param [String] privilege_id id of privilege to lookup in local privileges array
  # @param [String] entity_id id of entity to lookup in local privileges array
  # @return [true, false] indicating if user has / does not have privilege
  def has_privilege_on?(privilege_id, entity_id)
    @roles ||= []
    @roles.each { |r| return true if r.has_privilege_on?(privilege_id, entity_id) }
    return false
  end

  # Returns boolean indicating if the user has the specified privilege
  #
  # @param [String] privilege_id id of privilege to lookup in local privileges array
  # @return [true, false] indicating if user has / does not have privilege
  def has_privilege?(privilege_id)
    has_privilege_on?(privilege_id, nil)
  end

  # Return roles in json format
  def roles_json
    {:roles => roles}
  end
end # module HasRoles
end # module Users
