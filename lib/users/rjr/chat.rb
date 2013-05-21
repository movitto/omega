# users::send_message, users::subscribe_to_messages.
# users::get_messages rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

send_message = proc { |message|
  raise ArgumentError, "message must be a string of non-zero length" unless message.is_a?(String) && message != ""

  user = Users::Registry.instance.current_user :session => @headers['session_id']

  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user.id}"},
                                             {:privilege => 'modify', :entity => 'users'}],
                                    :session   => @headers['session_id'])

  Users::ChatProxy.proxy_for(user.id).proxy_message message
  nil
}

subscribe_to_messages = proc {
  user = Users::Registry.instance.current_user :session => @headers['session_id']

  # TODO ensure that rjr_node_type supports persistant connections

  Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "user-#{user.id}"},
                                             {:privilege => 'view', :entity => "users_entity-#{user.id}"},
                                             {:privilege => 'view', :entity => 'users_entities'}],
                                    :session => @headers['session_id'])

  callback = Users::ChatCallback.new { |message|
    begin
      @rjr_callback.invoke('users::on_message', message)
    rescue RJR::Errors::ConnectionError => e
      RJR::Logger.warn "subscribe_to_messages #{user.id} client disconnected"
      # Users::ChatProxy.proxy_for(user.id).remove_callback # TODO
    end
  }

  #@rjr_node.on(:closed) { |node|
  # Users::ChatProxy.proxy_for(user.id).remove_callback # TODO
  #}

  Users::ChatProxy.proxy_for(user.id).connect.add_callback callback
  nil
}

get_messages = proc {
  user = Users::Registry.instance.current_user :session => @headers['session_id']

  Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "user-#{user.id}"},
                                             {:privilege => 'view', :entity => "users_entity-#{user.id}"},
                                             {:privilege => 'view', :entity => 'users_entities'}],
                                    :session => @headers['session_id'])

  Users::ChatProxy.proxy_for(user.id).messages
}

def dispatch_chat(dispatcher)
  dispatcher.handle 'users::send_message', &send_message
  dispatcher.handle 'users::subscribe_to_messages', &subscribe_to_messages
  dispatcher.handle 'users::get_messages', &get_messages
end
