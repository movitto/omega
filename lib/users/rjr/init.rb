# Initialize the users subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/chat_proxy'
require 'users/registry'
require 'rjr/nodes/local'
require 'omega/exceptions'
require 'omega/server/dsl'

module Users::RJR
  include Omega#::Exceptions
  include Users
  include Omega::Server::DSL

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

  # @!endgroup
  end

  # Set config options using Omega::Config instance
  #
  # @param [Omega::Config] config object containing config options
  def self.set_config(config)
    self.user_attrs_enabled = config.user_attrs_enabled
    self.recaptcha_enabled  = config.recaptcha_enabled
    self.recaptcha_pub_key  = config.recaptcha_pub_key
    self.recaptcha_priv_key = config.recaptcha_priv_key
    self.omega_url          = config.omega_url
    self.permenant_users    = config.permenant_users
    self.users_rjr_username = config.users_rjr_user
    self.users_rjr_password = config.users_rjr_pass
  end

def self.user
  @user ||= Users::User.new(:id       => Users::RJR::users_rjr_username,
                            :password => Users::RJR::users_rjr_password,
                            :registration_code => nil)
end

def user
  Users::RJR.user
end

def self.node
  @node ||= ::RJR::Nodes::Local.new :node_id => self.user.id
end

def node
  Users::RJR.node
end

def self.registry
  @registry ||= Users::Registry.new
end

def registry
  Users::RJR.registry
end

def self.reset
  Users::RJR.registry.clear!
  Users::ChatProxy.clear
end

end # module Users::RJR

def dispatch_init(dispatcher)
  # init defaults
  Users::RJR.permenant_users ||= []

  # setup Users::RJR module
  rjr = Object.new.extend(Users::RJR)
  rjr.node.dispatcher = dispatcher
  rjr.node.dispatcher.env /users::.*/, Users::RJR
  rjr.node.message_headers['source_node'] = 'users'

  # ignore err if user already created
  begin rjr.node.invoke('users::create_user', rjr.user)
  rescue Exception => e ; end

  session = rjr.node.invoke('users::login', rjr.user)
  rjr.node.message_headers['session_id'] = session.id
end
