# Users module user definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/password_helper'

require 'omega/common'
require 'users/role'
require 'users/attribute'

module Users

# Entity central to the Users subsystem representing an end user
# which may be assigned roles containing privleges  to query / operate
# on one or more entities
class User
  # [String] unique string identifier of the user
  attr_accessor :id

  # [String] string email of the user
  attr_accessor :email

  # [Array<Users::Role>] array of roles the user has
  attr_accessor :roles

  # [String] user password (encrypted if secure_password is enabled)
  attr_reader :password

  # Set user password. Will be encrypted if secure_pasword is enabled
  def password=(v)
    @password = v
    if @secure_password
      @password = PasswordHelper.update(@password)
    end
  end

  # Boolean indicating if we should take additional steps to secure pass
  attr_reader :secure_password

  # Set password security on / off
  #
  # FIXME since password helper uses one way encryption setting to
  # false would have no effect, and setting to true multiple times
  # would render the password invalid. Need to fix this.
  def secure_password=(v)
    v = @secure_password unless [true, false].include?(v)
    @secure_password = v
    if @secure_password
      # encrypt password w/ salt
      @password = PasswordHelper.update(@password)
    end
  end

  # Registration code, set on new user registration then deleted on confirmation.
  # If set the user has registered but hasn't confirmed their email yet
  attr_accessor :registration_code

  # Recaptcha challenge from new account request
  attr_accessor :recaptcha_challenge

  # Recaptcha response from new account request
  attr_accessor :recaptcha_response

  # Time user account was created
  attr_accessor :created_at

  # Time user account was last modified
  attr_accessor :last_modified_at

  # Time user last logged in
  attr_accessor :last_login_at

  # [Boolean] indicating if this user is permenantly logged in
  attr_accessor :permenant

  # [Boolean] indicating if this user is a npc
  # TODO prohibit npcs from logging in?
  attr_accessor :npc

  # List of attributes currently owned by the user
  attr_accessor :attributes

  # Callbacks to invoke on various attribute related events TODO
  # attr_accessor :attribute_callbacks

  # Return overall user level calculated from attributes
  def level
    # TODO
  end

  # User initializer
  # @param [Hash] args hash of options to initialize user with
  # @option args [String] :id,'id' id to assign to the user
  # @option args [String] :email,'email' email to assign to the user
  # @option args [String] :password,'password' password to assign to the user
  # @option args [String] :registration_code,'registration_code' registration_code to assign to the user
  # @option args [String] :recaptcha_challenge,'recaptcha_challenge' recaptcha_challenge to assign to the user
  # @option args [String] :recaptcha_response,'recaptcha_response' recaptcha_response to assign to the user
  def initialize(args = {})
    attr_from_args args,
                   :id => nil, :email => nil, :password => nil,
                   :registration_code => -1, # nil registration code has special value
                   :recaptcha_challenge => nil,
                   :recaptcha_response  => nil,
                   :npc => false, :attributes => nil,
                   :secure_password => false, :permenant => false,
                   :roles => roles

    @attributes.each { |attr|
      attr.user = self
    } if @attributes
  end

  # Update this users's properties from other user.
  #
  # @param [Users::User] new_user user from which to copy values from
  def update(new_user)
    @last_modified_at = Time.now

    # update select attributes
    #@email             = new_user.email
    @registration_code =
      new_user.registration_code unless new_user.registration_code == -1
    @roles             = new_user.roles unless new_user.roles.nil?
    @attributes        = new_user.attributes unless new_user.attributes.nil?

    if new_user.password
      @password = new_user.password

      # XXX hack, ensure password is salted after updating if necessary
      self.secure_password=@secure_password
    end
  end

  #def ==(user)
    # TODO!
  #end

  # Updates user attribute with specified change
  #
  # @param [String] attribute_id id of attribute to update
  # @param [Integer,Float] change positive/negative amount to change attribute progression by
  def update_attribute!(attribute_id, change)
    @attributes ||= []
    attribute = @attributes.find { |a| a.type.id == attribute_id }

    if attribute.nil?
      # TODO also need to assign permissions to view attribute to user
      attribute = AttributeClass.create_attribute(:type_id => attribute_id)
      attribute.user = self
      raise ArgumentError, "invalid attribute #{attribute_id}" if attribute.type.nil?
      @attributes << attribute
    end

    attribute.update!(change)
    attribute
  end

  # Return boolean indicating if the user has the specified attribute
  # at an optional minimum level
  def has_attribute?(attribute_id, level = nil)
    @attributes ||= []
    !@attributes.find { |a| a.type.id == attribute_id.intern &&
                           (level.nil? || a.level >= level ) }.nil?
  end

  # Return attribute w/ the specified id, else null
  def attribute(attribute_id)
    @attributes ||= []
    @attributes.find { |a| a.type.id == attribute_id.intern }
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
                          @roles.include?(role) ||
                         !@roles.find { |r| r.id == role.id }.nil?
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
    valid_email?          &&
    id.is_a?(String)      && !id.empty? &&
    password.is_a?(String) && !password.empty?
    # TODO validate roles
  end

  # Returns boolean indicating if email is valid
  #
  # @return [true, false] if email matches valid regex
  def valid_email?
    !(self.email =~ (/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i)).nil?
  end

  # Returns boolean indicating if login credentials are valid for the current user
  #
  # @param [String] user_id id of user to compare against local @id attribute
  # @param [String] password password to encrypt and compare against the local @password parameter
  # @return [true, false] indicating if login are credentials are valid for user
  def valid_login?(user_id, password)
    self.id == user_id && self.registration_code.nil? &&
    (@secure_password ? PasswordHelper.check(password, self.password) : password == self.password)
  end

  # Adds the specified privilege to the first user role
  #
  # @param [Users::Privilege] privilege Privilege to add to user role
  #def add_privilege(privilege)
  #  # TODO select other role, or allow invoker to specify?
  #  # TODO raise error if no roles
  #  @roles.first.add_privilege(privilege) unless @roles.empty?
  #end

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

  # Convert user to human readable string and return it
  def to_s
    "user-#{@id}"
  end

  # Convert user to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :email => email, :roles => roles,
                       :permenant => permenant, :npc => npc, :attributes => attributes,
                      }.merge(@secure_password ? {} : {:password => password, :registration_code => registration_code})
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

end
end
