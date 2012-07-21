# Users module user definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users
class User
  attr_accessor :id
  attr_accessor :email
  attr_accessor :password
  attr_accessor :alliances

  attr_reader :privileges

  # registration code, if set the user has registered
  # but hasn't confirmed their email yet
  attr_accessor :registration_code

  # recaptcha values comes in on new account requests, verify
  attr_accessor :recaptcha_challenge
  attr_accessor :recaptcha_response

  attr_accessor :created_at
  attr_accessor :last_modified_at
  attr_accessor :last_login_at

  def initialize(args = {})
    @id        = args['id']        || args[:id]
    @email     = args['email']     || args[:email]
    @password  = args['password']  || args[:password]
    @alliances = args['alliances'] || args[:alliances] || []
    @registration_code   = args['registration_code'] || args[:registration_code]
    @recaptcha_challenge = args['recaptcha_challenge']  || args[:recaptcha_challenge]
    @recaptcha_response  = args['recaptcha_response']  || args[:recaptcha_response]
    # FIXME encrypt password w/ salt

    @privileges = []
  end

  def update!(new_user)
    @last_modified_at = Time.now
    @password = new_user.password
  end

  def add_alliance(alliance)
    @alliances << alliance unless !alliance.is_a?(Users::Alliance) ||
                                  @alliances.collect{ |a| a.id }.
                                    include?(alliance.id)
  end

  def clear_privileges
    @privileges.clear
  end

  def add_privilege(privilege)
    @privileges << privilege unless privilege.nil? ||
                                     @privileges.include?(privilege) ||
                                    !@privileges.find { |p| p.id == privilege.id && p.entity_id == privilege.entity_id }.nil?
  end

  def valid_email?
    self.email =~ (/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i)
  end

  def valid_login?(user_id, password)
    self.id == user_id && self.password == password && self.registration_code.nil?
  end

  def has_privilege_on?(privilege_id, entity_id)
    ! @privileges.find { |p| p.id == privilege_id && p.entity_id == entity_id }.nil?
  end

  def has_privilege?(privilege_id)
    has_privilege_on?(privilege_id, nil)
  end

  def to_s
    "user-#{@id}"
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id,
                       :email => email, :password => password, # FIXME filter password when sending user to client
                       :registration_code => registration_code,
                       :alliances => alliances}
    }.to_json(*a)
  end

  def self.json_create(o)
    user = new(o['data'])
    return user
  end

  def self.random_registration_code
    Users.random_string(8)
  end

end
end
