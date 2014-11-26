# Users module role definition
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'users/privilege'

module Users

# Entity representing a collection of privileges which may be
# associated with entities. May be assigned to a user
class Role
  # [String] unique string identifier of the role
  attr_accessor :id

  # [Array<Users::Privilege>] array of privileges associated with the role
  attr_reader :privileges

  # Role initializer
  # @param [Hash] args hash of options to initialize user with
  # @option args [String] :id,'id' id to assign to the user
  # @option args [Array<Users::Privilege>] :privlieges,'privileges' privileges to assign to role
  def initialize(args = {})
    @id        = args['id']        || args[:id]
    @privileges = args['privileges'] || args[:privileges] || []
  end

  # Update this roles's properties from other roles.
  #
  # @param [Users::Role] new_role role from which to copy values from
  def update(new_role, *attrs)
    #@id = new_role.id
    @privileges = new_role.privileges
  end

  # Clear the privileges the role has
  def clear_privileges
    @privileges.clear
  end

  # Adds the privilege specified by its arguments to the role
  #
  # @param [Array<Users::Privilege>,Array<String,String>] args catch all array of args to use when adding privilege.
  #   May take one of two forms specifying the instance of the privilege class itself to add, or an id and entity_id
  #   to create the privilege with
  def add_privilege(*args)
    privilege = args[0].is_a?(Users::Privilege) ?
                args[0] : Privilege.new(:id => args.first)

    if privilege.entity_id.nil? && !args[1].nil?
      privilege.entity_id = args[1]
    end

    @privileges << privilege unless privilege.nil? ||
                                     @privileges.include?(privilege) ||
                                    !@privileges.find { |p| p.id == privilege.id && p.entity_id == privilege.entity_id }.nil?
  end

  # Remove privilege from role
  #
  # @param privilege_id id of the privilege to remove
  # @param entity_id optional id of the entity which to remove privilege to
  def remove_privilege(privilege_id, entity_id=nil)
    @privileges.reject! { |p| p.id == privilege_id && p.entity_id == entity_id }
  end

  # Returns boolean indicating if the role has the specified privilege on the specified entity
  #
  # @param [String] privilege_id id of privilege to lookup in local privileges array
  # @param [String] entity_id id of entity to lookup in local privileges array
  # @return [true, false] indicating if user has / does not have privilege
  def has_privilege_on?(privilege_id, entity_id)
    ! @privileges.find { |p| p.id == privilege_id && p.entity_id == entity_id }.nil?
  end

  # Returns boolean indicating if the role has the specified privilege
  #
  # @param [String] privilege_id id of privilege to lookup in local privileges array
  # @return [true, false] indicating if user has / does not have privilege
  def has_privilege?(privilege_id)
    has_privilege_on?(privilege_id, nil)
  end

   # Convert role to human readable string and return it
  def to_s
    "role-#{@id}"
  end

  # Convert role to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :privileges => privileges}
    }.to_json(*a)
  end

  # Create new role from json representation
  def self.json_create(o)
    role = new(o['data'])
    return role
  end

end
end
