# Initialize the users subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

class << self
  # @!group Config options

  # Boolean toggling if user attribute system is enabled / disabled.
  # Disabling attributes will result in setting attributes having
  # no effect and all has_attribute? calls returning true
  attr_accessor :user_attrs_enabled

  # Boolean toggling if recaptchas are enabled / required for user registration
  # @!scope class
  attr_accessor :recaptcha_enabled

  # String recaptch public key
  # @!scope class
  attr_accessor :recaptcha_pub_key

  # String recaptch private key
  # @!scope class
  attr_accessor :recaptcha_priv_key

  # String URL of the omega server
  # @!scope class
  attr_accessor :omega_url

  # Array<String> Usernames to mark as permenant on creation
  attr_accessor :permenant_users

  # User to use to communicate w/ other modules over the local rjr node
  attr_accessor :users_rjr_username

  # Password to use to communicate w/ other modules over the local rjr node
  attr_accessor :users_rjr_password

  # Set config options using Omega::Config instance
  #
  # @param [Omega::Config] config object containing config options
  def set_config(config)
    self.user_attrs_enabled = config.user_attrs_enabled
    self.recaptcha_enabled  = config.recaptcha_enabled
    self.recaptcha_pub_key  = config.recaptcha_pub_key
    self.recaptcha_priv_key = config.recaptcha_priv_key
    self.omega_url          = config.omega_url
    self.permenant_users    = config.permenant_users
    self.users_rjr_username = config.users_rjr_user
    self.users_rjr_password = config.users_rjr_pass
  end

  # @!endgroup
end

def users_user
  user ||= Users::User.new(:id       => Users::RJRAdapter.users_rjr_username,
                           :password => Users::RJRAdapter.users_rjr_password)
end

def dispatch_init(dispatcher)
  self.permenant_users = [] if self.permenant_users.nil?
  
  Users::ChatProxy.clear
  Users::Registry.instance.init
  node = RJR::LocalNode.new :node_id => 'users'
  node.message_headers['source_node'] = 'users'
  node.invoke_request('users::create_entity', self.user)
  
  session = node.invoke_request('users::login', self.user)
  node.message_headers['session_id'] = session.id
end
