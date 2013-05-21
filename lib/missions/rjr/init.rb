# Initialize the missions subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

class << self
  # @!group Config options

  # User to use to communicate w/ other modules over the local rjr node
  attr_accessor :missions_rjr_username

  # Password to use to communicate w/ other modules over the local rjr node
  attr_accessor :missions_rjr_password

  # Set config options using Omega::Config instance
  #
  # @param [Omega::Config] config object containing config options
  def set_config(config)
    self.missions_rjr_username  = config.missions_rjr_user
    self.missions_rjr_password  = config.missions_rjr_pass
  end

  # @!endgroup
end

manufactured_event = proc { |*args|
  raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE

  event = Missions::Events::Manufactured.new *args
  Missions::Registry.instance.create event
  nil
}

def missions_user
  user ||= Users::User.new(:id       => Missions::RJRAdapter.missions_rjr_username,
                           :password => Missions::RJRAdapter.missions_rjr_password)
end

def dispatch_init(dispatcher)
  Missions::Registry.instance.init

  node = RJR::LocalNode.new :node_id => 'missions'
  node.message_headers['source_node'] = 'missions'

  # Set shared node which events may use
  Missions::Event.node = node

  node.invoke_request('users::create_entity', self.user)
  role_id = "user_role_#{self.user.id}"
  # all in all missions is a pretty powerful role/user in terms
  #  of what it can do w/ the simulation
  node.invoke_request('users::add_privilege', role_id, 'view',     'users_entities')
  node.invoke_request('users::add_privilege', role_id, 'view',     'cosmos_entities')
  node.invoke_request('users::add_privilege', role_id, 'modify',   'cosmos_entities')
  node.invoke_request('users::add_privilege', role_id, 'view',     'manufactured_entities')
  node.invoke_request('users::add_privilege', role_id, 'create',   'manufactured_entities')
  node.invoke_request('users::add_privilege', role_id, 'modify',   'manufactured_entities')
  node.invoke_request('users::add_privilege', role_id, 'modify',   'manufactured_resources')
  node.invoke_request('users::add_privilege', role_id, 'create',   'missions')

  session = node.invoke_request('users::login', self.user)
  node.message_headers['session_id'] = session.id

  dispatcher.handle('manufactured::event_occurred', &manufactured_event)
end
