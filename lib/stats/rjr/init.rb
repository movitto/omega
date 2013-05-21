# Initialize the stats subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

class << self
  # @!group Config options

  # User to use to communicate w/ other modules over the local rjr node
  attr_accessor :stats_rjr_username

  # Password to use to communicate w/ other modules over the local rjr node
  attr_accessor :stats_rjr_password

  # Set config options using Omega::Config instance
  #
  # @param [Omega::Config] config object containing config options
  def set_config(config)
    self.stats_rjr_username  = config.stats_rjr_user
    self.stats_rjr_password  = config.stats_rjr_pass
  end

  # @!endgroup
end

def stats_user
  user ||= Users::User.new(:id       => Stats::RJRAdapter.stats_rjr_username,
                           :password => Stats::RJRAdapter.stats_rjr_password)
end

def dispatch_init(dispatcher)
  Stats::Registry.instance.init
  node = RJR::LocalNode.new :node_id => 'manufactured'
  node.message_headers['source_node'] = 'manufactured'
  node.invoke_request('users::create_entity', self.user)
  role_id = "user_role_#{self.user.id}"
  node.invoke_request('users::add_privilege', role_id, 'view',   'manufactured_entities')
  node.invoke_request('users::add_privilege', role_id, 'view',   'cosmos_entities')
  node.invoke_request('users::add_privilege', role_id, 'view',   'users_entities')
  node.invoke_request('users::add_privilege', role_id, 'view',   'missions')

  session = node.invoke_request('users::login', self.user)
  node.message_headers['session_id'] = session.id
  Stats::Registry.instance.node = node
end
