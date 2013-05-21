# users::update_attribute, users::has_attribute? rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

update_attribute = proc { |user_id,attribute_id,change|
  raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE

  Users::Registry.require_privilege(:privilege => 'modify', :entity => "user_attributes",
                                    :session   => @headers['session_id'])

  user = Users::Registry.instance.find(:id => user_id, :type => "Users::User").first
  raise Omega::DataNotFound, "user specified by user_id #{user_id} not found" if user.nil?

  #Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user.id}"},
  #                                           {:privilege => 'modify', :entity => 'users'}],
  #                                  :session   => @headers['session_id'])


  if Users::RJRAdapter.user_attrs_enabled
    Users::Registry.instance.safely_run {
      user.update_attribute!(attribute_id, change)
    }
  end

  user
}

has_attribute = proc { |*args|
  user_id = args[0]
  attr_id = args[1]
  level   = args.size > 2 ? args[2] : 0
  raise ArgumentError, "must specify a valid user id"      unless user_id.is_a?(String)
  raise ArgumentError, "must specify a valid attribute id" unless attr_id.is_a?(String)
  raise ArgumentError, "must specify a valid level"        unless level.is_a?(Integer) && level >= 0

  Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "user_attributes"},
                                             {:privilege => 'view', :entity => "user_attributes-#{user_id}"},
                                             {:privilege => 'view', :entity => "user_attribute-#{user_id}_#{attr_id}"}],
                                    :session   => @headers['session_id'])

  user = Users::Registry.instance.find(:id => user_id, :type => "Users::User").first
  raise Omega::DataNotFound, "user specified by user_id #{user_id} not found" if user.nil?

  if Users::RJRAdapter.user_attrs_enabled
    Users::Registry.instance.safely_run {
      user.has_attribute?(attr_id, level)
    }
  else
    true
  end
}

def dispatch_attribute(dispatcher)
  dispatcher.handle 'users::update_attribute', &update_attribute
  dispatcher.handle 'users::has_attribute?',   &has_attribute

  # TODO allow client to subscribe to attribute changes
  # dispatcher.handle('users::subscribe_to_progression') ...
end
