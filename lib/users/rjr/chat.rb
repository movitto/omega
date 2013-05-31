# users::send_message, users::subscribe_to_messages.
# users::get_messages rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/common' # for logger

module Users::RJR

# Send message to chat server
send_message = proc { |message|
  # validate message
  raise ArgumentError,
    "message must be valid" unless message.is_a?(String) && message != ""

  # ensure logged in user can be modified
  require_privilege :registry => registry, :any =>
    [{:privilege => 'modify', :entity => "user-#{current_user.id}"},
     {:privilege => 'modify', :entity => 'users'}]

  # send message
  Users::ChatProxy.proxy_for(current_user.id).proxy_message message

  # return nil
  nil
}

# Subscribe to new incoming messages
subscribe_to_messages = proc {
  # TODO ensure that rjr_node_type supports persistant connections

  # setup a callback to send chat messages back to client
  callback = Users::ChatCallback.new { |message|
    begin
      # ensure logged in user can be viewed
      require_privilege(:any =>
        [{:privilege => 'view', :entity => "user-#{current_user.id}"},
         {:privilege => 'view', :entity => "users_entity-#{current_user.id}"},
         {:privilege => 'view', :entity => 'users_entities'}])


      @rjr_callback.notify('users::on_message', message)
    rescue Omega::PermissionError => e
      RJR::Logger.warn "subscribe_to_messages #{current_user.id} permission err #{e}"
      # Users::ChatProxy.proxy_for(current_user.id).remove_callback # TODO

    rescue RJR::Errors::ConnectionError => e
      RJR::Logger.warn "subscribe_to_messages #{current_user.id} client disconnected"
      # Users::ChatProxy.proxy_for(user.id).remove_callback
    
    rescue Exception => e
      RJR::Logger.warn "exception raised when invoking #{current_user.id} callbacks"
      # Users::ChatProxy.proxy_for(user.id).remove_callback
    end
  }

  # delete callback on connection events
  #@rjr_node.on(:closed) { |node|
  # Users::ChatProxy.proxy_for(user.id).remove_callback
  #}

  # subscribe to messages
  Users::ChatProxy.proxy_for(user.id).connect.add_callback callback

  # return nil
  nil
}

# Retrieve all messages sent by user
get_messages = proc {
  # ensure logged in user can be viewed
  require_privilege :any =>
    [{:privilege => 'view', :entity => "user-#{user.id}"},
     {:privilege => 'view', :entity => "users_entity-#{user.id}"},
     {:privilege => 'view', :entity => 'users_entities'}]

  # retrieve all messages
  Users::ChatProxy.proxy_for(user.id).messages
}

CHAT_METHODS = { :send_message          => send_message,
                 :subscribe_to_messages => subscribe_to_messages,
                 :get_messages          => get_messages}

end # module Users::RJR

def dispatch_chat(dispatcher)
  m = Users::RJR::CHAT_METHODS
  dispatcher.handle 'users::send_message',          &m[:send_message]
  dispatcher.handle 'users::subscribe_to_messages', &m[:subscribe_to_messages]
  dispatcher.handle 'users::get_messages',          &m[:get_messages]
end
