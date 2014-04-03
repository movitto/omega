# missions::subscribe_to, missions::unsubscribe rjr definitions
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'missions/rjr/init'

module Missions::RJR

# subscribe client to missions event
subscribe_to = proc { |event_type, *args|
  # validate persistent transport, source node, & source/session match
  require_persistent_transport!
  require_valid_source!
  validate_session_source! :registry => user_registry

  args = args.empty? ? {} : Hash[*args]
  valid_filters =
    Missions::EventHandlers::MissionEventHandler.valid_filters?(args.keys)
  raise ArgumentError, args unless valid_filters

  # create a new persistent event handler to send notifications back to client
  handler = Missions::EventHandlers::MissionEventHandler.new args
  handler.endpoint_id = @rjr_headers['source_node']
  handler.persist = true
  handler.event_type  = event_type
  handler.exec do |omega_event|
    err = false

    begin
      # require view on missions_events
      require_privilege :registry  => user_registry,
                        :privilege => 'view',
                        :entity    => 'missions_events'
      # FIXME also require view privilege on mission itself

      # invoke method via rjr callback notification
      @rjr_callback.notify 'missions::event_occurred', event_type, *omega_event.event_args

    rescue Omega::PermissionError => e
      ::RJR::Logger.warn "missions event #{event_type} handler permission error #{e}"
      err = true

    rescue Omega::ConnectionError => e
      ::RJR::Logger.warn "missions event #{event_type} client disconnected #{e}"
      err = true
      # also entity.callbacks associated w/ @rjr_headers['session_id'] ?

    rescue Exception => e
      ::RJR::Logger.warn "exception during missions #{event_type} callback #{e} #{e.backtrace}"
      err = true

    ensure
      # remove handler on all errors
      delete_event_handler_for :event_type  => event_type,
                               :endpoint_id => handler.endpoint_id,
                               :registry    => registry             if err
    end
  end

  # delete callback on connection events
  handle_node_closed(@rjr_node) { |node|
    source_node = node.message_headers['source_node']
    delete_event_handler_for :event_type  => event_type,
                             :endpoint_id => source_node,
                             :registry    => registry
  }

  # add handler to registry (registry will ensure uniqueness)
  registry << handler

  # return nil
  nil
}

unsubscribe = proc { |event_type|
  # verify source node / session endpoint match
  require_valid_source!
  validate_session_source! :registry => user_registry
  source_node = @rjr_headers['source_node']

  # require view on missions events
  require_privilege :registry  => user_registry,
                    :privilege => 'view',
                    :entity    => 'missions_events'

  # remove registered handler
  delete_event_handler_for :event_type  => event_type,
                           :endpoint_id => source_node,
                           :registry    => registry

  # return nil
  nil
}

EVENTS_METHODS = { :subscribe_to     => subscribe_to,
                   :unsubscribe      => unsubscribe }
end

def dispatch_missions_rjr_events(dispatcher)
  m = Missions::RJR::EVENTS_METHODS
  dispatcher.handle 'missions::subscribe_to',     &m[:subscribe_to]
  dispatcher.handle 'missions::unsubscribe',       &m[:unsubscribe]
end
