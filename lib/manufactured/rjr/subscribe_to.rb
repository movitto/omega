# manufactured::subscribe_to rjr definition
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'
require 'manufactured/rjr/subscribe_to/subsystem_events'
require 'manufactured/rjr/subscribe_to/entity_events'

module Manufactured::RJR
  # subscribe client to manufactured event
  subscribe_to = proc { |*args|
    # validate persistent transport
    require_persistent_transport!

    # validate source node
    require_valid_source!

    # validate source/session match
    validate_session_source! :registry => user_registry

    # who is subscribing
    endpoint_id = @rjr_headers['source_node']

    raise ArgumentError if args.empty?

    if subsystem_event?(args.first)
      event_type = args.shift
      subscribe_to_subsystem_event event_type, endpoint_id, *args

      handle_node_closed(@rjr_node) { |node|
        source_node = node.message_headers['source_node']
        delete_event_handler_for :event_type  => event_type,
                                 :endpoint_id => source_node,
                                 :registry    => registry
      }

    else
      entity_id, event_type = *args

      entity = registry.entity &with_id(entity_id)
      raise DataNotFound, entity_id unless subscribable_entity?(entity)

      subscribe_to_entity_event entity_id, event_type, endpoint_id

      handle_node_closed(@rjr_node) { |node|
        source_node = node.message_headers['source_node']
        remove_callbacks_for registry, :id       => entity_id,
                                       :type     => event_type,
                                       :endpoint => source_node
      }
    end

    # return nil
    nil
  }

  SUBSCRIBE_TO_METHODS = {:subscribe_to => subscribe_to}

end # module Manufactured::RJR

def dispatch_manufactured_rjr_subscribe_to(dispatcher)
  m = Manufactured::RJR::SUBSCRIBE_TO_METHODS
  dispatcher.handle 'manufactured::subscribe_to',
                 &m[:subscribe_to]
end
