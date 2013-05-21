# Initialize the manufactured subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

class << self
  # @!group Config options

  # User to use to communicate w/ other modules over the local rjr node
  attr_accessor :manufactured_rjr_username

  # Password to use to communicate w/ other modules over the local rjr node
  attr_accessor :manufactured_rjr_password

  # Set config options using Omega::Config instance
  #
  # @param [Omega::Config] config object containing config options
  def set_config(config)
    self.manufactured_rjr_username  = config.manufactured_rjr_user
    self.manufactured_rjr_password  = config.manufactured_rjr_pass
  end

  # @!endgroup
end

# callback to track_movement and track_rotation in move_entity
motel_event = proc { |loc|
  raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
  entity = Manufactured::Registry.instance.find(:location_id => loc.id,
                                                :include_graveyard => true).first
  unless entity.nil?
    Manufactured::Registry.instance.safely_run {
      # XXX location may have been updated in the meantime
      entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))
  
      # update user attributes
      if(entity.location.movement_strategy.is_a?(Motel::MovementStrategies::Linear))
        @@local_node.invoke_request('users::update_attribute', entity.user_id,
                                    Users::Attributes::DistanceTravelled.id,
                                    entity.distance_moved)
        entity.distance_moved = 0
      end
  
      # update movement strategy
      entity.location.movement_strategy = entity.next_movement_strategy
  
      # update location
      loc = entity.location
      @@local_node.invoke_request('motel::update_location', loc)
  
      # remove callbacks if stopped
      if(entity.location.movement_strategy ==
         Motel::MovementStrategies::Stopped.instance)
        @@local_node.invoke_request('motel::remove_callbacks', loc.id, :movement)
        @@local_node.invoke_request('motel::remove_callbacks', loc.id, :rotation)
      end
    }
  end
}

def manufactured_user
  @user ||= Users::User.new(:id       => Manufactured::RJRAdapter.manufactured_rjr_username,
                            :password => Manufactured::RJRAdapter.manufactured_rjr_password)
end

def dispatch_init(dispatcher)
  Manufactured::Registry.instance.init
  node = RJR::LocalNode.new :node_id => 'manufactured'
  node.message_headers['source_node'] = 'manufactured'
  node.invoke_request('users::create_entity', manufactured_user)
  role_id = "user_role_#{manufactured_user.id}"
  node.invoke_request('users::add_privilege', role_id, 'view',   'cosmos_entities')
  node.invoke_request('users::add_privilege', role_id, 'modify', 'cosmos_entities')
  node.invoke_request('users::add_privilege', role_id, 'create', 'locations')
  node.invoke_request('users::add_privilege', role_id, 'view',   'users_entities')
  node.invoke_request('users::add_privilege', role_id, 'view',   'user_attributes')
  node.invoke_request('users::add_privilege', role_id, 'modify', 'user_attributes')
  node.invoke_request('users::add_privilege', role_id, 'view',   'locations')
  node.invoke_request('users::add_privilege', role_id, 'modify', 'locations')
  node.invoke_request('users::add_privilege', role_id, 'create', 'manufactured_entities')

  session = node.invoke_request('users::login', manufactured_user)
  node.message_headers['session_id'] = session.id

  dispatcher.handle(['motel::on_movement', 'motel::on_rotation'], &motel_event)
end
