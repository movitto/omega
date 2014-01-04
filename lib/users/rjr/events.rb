# users::subscribe_to, users::unsubscribe rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/rjr/init'

module Users::RJR

# Helper to delete event handler in registry for event/endpoint
def delete_handler_for(args={})
  event       = args[:event]
  endpoint_id = args[:endpoint_id]
  registry    = args[:registry]

  registry.delete { |entity|
    entity.is_a?(Omega::Server::EventHandler) &&
    entity.event_type == event &&
    entity.endpoint_id == endpoint_id
  }
end

# subscribe client to users event
subscribe_to = proc { |event|
  # validate persistent transport, source node, & source/session match
  require_persistent_transport!
  require_valid_source!
  validate_session_source! :registry => registry

  # create a new persistent event handler to send notifications back to client
  handler = Omega::Server::EventHandler.new
  handler.endpoint_id = @rjr_headers['source_node']
  handler.persist = true
  handler.event_type  = event
  handler.exec do |omega_event|
    err = false

    begin
      # require view on users_users
      require_privilege :registry  => registry,
                        :privilege => 'view',
                        :entity    => 'users_events'

      # invoke method via rjr callback notification
      @rjr_callback.notify 'users::event_occurred', event, *omega_event.event_args

    rescue Omega::PermissionError => e
      ::RJR::Logger.warn "users event #{event} handler permission error #{e}"
      err = true

    rescue ::RJR::Errors::ConnectionError => e
      ::RJR::Logger.warn "users event #{event} client disconnected #{e}"
      err = true
      # also entity.callbacks associated w/ @rjr_headers['session_id'] ?

    rescue Exception => e
      ::RJR::Logger.warn "exception during users #{event} callback #{e} #{e.backtrace}"
      err = true

    ensure
      # remove handler on all errors
      delete_handler_for :event       => event,
                         :endpoint_id => handler.endpoint_id,
                         :registry    => registry             if err
    end
  end

  # delete callback on connection events
  @rjr_node.on(:closed){ |node|
    delete_handler_for :event       => event,
                       :endpoint_id => handler.endpoint_id,
                       :registry    => registry
  }

  # add handler to registry (registry will ensure uniqueness)
  registry << handler

  # return nil
  nil
}

unsubscribe = proc { |event|
  # verify source node / session endpoint match
  require_valid_source!
  validate_session_source! :registry => registry
  source_node = @rjr_headers['source_node']

  # require view on users entities
  require_privilege :registry  => registry,
                    :privilege => 'view',
                    :entity    => 'users_events'

  # remove registered handler
  delete_handler_for :event       => event,
                     :endpoint_id => source_node,
                     :registry    => registry

  # return nil
  nil
}

EVENTS_METHODS = { :subscribe_to     => subscribe_to,
                   :unsubscribe      => unsubscribe }
end

def dispatch_users_rjr_events(dispatcher)
  m = Users::RJR::EVENTS_METHODS
  dispatcher.handle 'users::subscribe_to',     &m[:subscribe_to]
  dispatcher.handle 'users::unsubscribe',       &m[:unsubscribe]
end
