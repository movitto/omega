# Initialize the cosmos subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

class << self
  # @!group Config options

  # User to use to communicate w/ other modules over the local rjr node
  attr_accessor :cosmos_rjr_username

  # Password to use to communicate w/ other modules over the local rjr node
  attr_accessor :cosmos_rjr_password

  # Set config options using Omega::Config instance
  #
  # @param [Omega::Config] config object containing config options
  def set_config(config)
    self.cosmos_rjr_username  = config.cosmos_rjr_user
    self.cosmos_rjr_password  = config.cosmos_rjr_pass
  end

  # @!endgroup
end

def cosmos_user
  @user ||= Users::User.new(:id       => Cosmos::RJRAdapter.cosmos_rjr_username,
                            :password => Cosmos::RJRAdapter.cosmos_rjr_password)
end

def dispatch_init(dispatcher)
  Cosmos::Registry.instance.init
  node = RJR::LocalNode.new :node_id => 'cosmos'
  node.message_headers['source_node'] = 'cosmos'
  node.invoke_request('users::create_entity', cosmos_user)
  role_id = "user_role_#{cosmos_user.id}"
  node.invoke_request('users::add_privilege', role_id, 'view',   'locations')
  node.invoke_request('users::add_privilege', role_id, 'create', 'locations')

  session = node.invoke_request('users::login', cosmos_user)
  node.message_headers['session_id'] = session.id
end
