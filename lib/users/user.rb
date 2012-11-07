# Users module user definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

# Entity central to the Users subsystem representing an end user
# which may be assigned roles containing privleges  to query / operate
# on one or more entities
class User
  # [String] unique string identifier of the user
  attr_accessor :id

  # [String] string email of the user
  attr_accessor :email

  # [Array<Users::Alliance>] array of alliances user belongs to
  attr_accessor :alliances

  # [Array<Users::Role>] array of roles the user has
  attr_reader :roles

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

  # User initializer
  # @param [Hash] args hash of options to initialize user with
  # @option args [String] :id,'id' id to assign to the user
  # @option args [String] :email,'email' email to assign to the user
  # @option args [String] :password,'password' password to assign to the user
  # @option args [Array<Users::Alliance>] :alliances,'alliances' alliances to assign to user
  # @option args [String] :registration_code,'registration_code' registration_code to assign to the user
  # @option args [String] :recaptcha_challenge,'recaptcha_challenge' recaptcha_challenge to assign to the user
  # @option args [String] :recaptcha_response,'recaptcha_response' recaptcha_response to assign to the user
  def initialize(args = {})
    @id        = args['id']        || args[:id]
    @email     = args['email']     || args[:email]
    @password  = args['password']  || args[:password]
    @alliances = args['alliances'] || args[:alliances] || []
    @registration_code   = args['registration_code'] || args[:registration_code]
    @recaptcha_challenge = args['recaptcha_challenge']  || args[:recaptcha_challenge]
    @recaptcha_response  = args['recaptcha_response']  || args[:recaptcha_response]
    @secure_password = false
    @permenant       = false

    @roles = []
  end

  # Update this users's attributes from other users.
  #
  # Currently this only copies the password and secure_password
  # attributes.
  #
  # @param [Motel::Users] new_user user from which to copy values from
  def update!(new_user)
    @last_modified_at = Time.now
    @password = new_user.password

    # XXX hack, ensure password is salted after updating if necessary
    self.secure_password=@secure_password
  end

  # Adds an alliance to user.
  #
  # Will just ignore and return if alliance is already associated with user
  #
  # @param [Users::Alliance] alliance to add to the user
  def add_alliance(alliance)
    @alliances << alliance unless !alliance.is_a?(Users::Alliance) ||
                                  @alliances.collect{ |a| a.id }.
                                    include?(alliance.id)
  end

  # Clear the roles the user has
  def clear_roles
    @roles.clear
  end

  # Adds the roles specified by its arguments to the user
  #
  # @param [Users::Role] role role to add to user
  def add_role(role)
    @roles << role unless role.nil? ||
                          @roles.include?(role) ||
                         !@roles.find { |r| r.id == role.id }.nil?
  end

  # Returns boolean indicating if email is valid
  #
  # @return [true, false] if email matches valid regex
  def valid_email?
    self.email =~ (/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i)
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
    @roles.collect { |r| r.privileges }.flatten.uniq
  end

  # Returns boolean indicating if the user has the specified privilege on the specified entity
  #
  # @param [String] privilege_id id of privilege to lookup in local privileges array
  # @param [String] entity_id id of entity to lookup in local privileges array
  # @return [true, false] indicating if user has / does not have privilege
  def has_privilege_on?(privilege_id, entity_id)
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
      'data'       => {:id => id, :email => email, :alliances => alliances,
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
