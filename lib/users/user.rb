# Users module user definition
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/common'
require 'users/mixins/user'

module Users

# Entity central to the Users subsystem representing an end user
# which may be assigned roles containing privleges  to query / operate
# on one or more entities
class User
  include BaseAttrs
  include HasRoles
  include SecurePassword
  include Registerable
  include HasAttributes

  # User initializer
  # @param [Hash] args hash of options to initialize user with, accepts
  #   key/value pairs corresponding to all mutable user attributes
  def initialize(args = {})
    base_attrs_from_args   args
    roles_from_args        args
    password_from_args     args
    registration_from_args args
    attributes_from_args   args
  end

  # Update this users's properties from other user.
  #
  # @param [Users::User] new_user user from which to copy values from
  def update(user)
    update_base_attrs(user)
    update_registration(user)
    update_roles(user)
    update_attributes(user)
    update_password(user)
  end

  # Return boolean indicating if the user is valid.
  #
  # Note special users such as the admin aren't constrained
  # to these retrictions
  #
  # Currently tests:
  # * email is valid
  # * id is valid
  # * password is valid
  #
  # @return bool indicating if the user is valid or not
  def valid?
    valid_base_attrs? && valid_password?
    # TODO validate roles
  end

  # Returns boolean indicating if login credentials are valid for the current user
  #
  # @param [String] user_id id of user to compare against local @id attribute
  # @param [String] password password to encrypt and compare against the local @password parameter
  # @return [true, false] indicating if login are credentials are valid for user
  def valid_login?(user_id, password)
    id == user_id && registration_code.nil? && password_matches?(password)
  end

  # Convert user to human readable string and return it
  def to_s
    "user-#{@id}"
  end

  # Convert user to json representation and return it
  def to_json(*a)
    {'json_class' => self.class.name,
     'data'       => base_json.merge(roles_json).
                               merge(attributes_json).
                               merge(password_json).
                               merge(registration_json)
    }.to_json(*a)
  end

  # Create new user from json representation
  def self.json_create(o)
    user = new(o['data'])
    return user
  end

  # Generate random string registration code
  def self.random_registration_code
    Users.random_string(8)
  end
end # class User
end # module Users
