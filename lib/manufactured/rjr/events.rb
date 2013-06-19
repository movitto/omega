# manufactured::subscribe_to, manufactured::remove_callbacks
# rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'

module Manufactured::RJR

# subscribe client to manufactured event
subscribe_to = proc { |entity_id, event|
  entity = registry.entity &with_id(entity_id)
  raise DataNotFound,
           entity_id if entity.nil? ||
                       ![Station, Ship].include?(entity.class)

  # grab direct handle to registry entity
  rentity = registry.safe_exec { |entities| entities.find &with_id(entity.id) }

  # TODO option to verify request is coming from
  #      authenticated source node which current
  #      connection was established on

  # TODO ensure that rjr_node_type supports
  #      persistant connections

  cb = Omega::Server::Callback.new
  cb.endpoint_id = @rjr_headers['source_node']
  cb.rjr_event   = 'manufactured::event_occurred'
  cb.event_type  = event
  cb.handler =
    proc { |*args|
      entity = args.first
      err = false

      begin
        # ensure user has access to view entity
        require_privilege :registry => user_registry, :any =>
          [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
           {:privilege => 'view', :entity => 'manufactured_entities'}]

        # invoke method via rjr callback notification
        @rjr_callback.notify 'manufactured::event_occurred', *args

      rescue Omega::PermissionError => e
        ::RJR::Logger.warn "entity #{entity.id} callback permission error #{e}"
        err = true

      rescue ::RJR::Errors::ConnectionError => e
        ::RJR::Logger.warn "entity #{entity.id} client disconnected"
        err = true
        # also entity.callbacks associated w/ @rjr_headers['session_id'] ?

      rescue Exception => e
        ::RJR::Logger.warn "exception during #{entity.id} callback"
        err = true

      ensure
        if err
          registry.safe_exec { |entities|
            rentity.callbacks.delete(cb)
            rentity.callbacks.compact!
          }
        end
      end
    }

  # delete callback on connection events
  @rjr_node.on(:closed){ |node|
    registry.safe_exec { |entities|
      rentity.callbacks.delete(cb)
      rentity.callbacks.compact!
    }
  }

  # delete old callback and register new
  registry.safe_exec { |entities|
    old = 
      rentity.callbacks.find { |c|
        c.event_type  == cb.event_type &&
        c.endpoint_id == cb.endpoint_id
      }
    rentity.callbacks.delete(old) if old.nil?
    rentity.callbacks.compact!
    rentity.callbacks << cb
  }

  # return entity
  entity
}

# remove callbacks registered for entity
remove_callbacks = proc { |entity_id|
  # TODO option to verify request is coming from
  #      authenticated source node which current
  #      connection was established on
  source_node = @rjr_headers['source_node']

  # retrieve/validate entity
  entity = registry.entity &with_id(entity_id)
  raise DataNotFound, entity_id if entity.nil? ||
                                   ![Station, Ship].include?(entity.class)

  # require view on entity
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
     {:privilege => 'view', :entity => 'manufactured_entities'}]

  # remove callbacks from registry entity
  registry.safe_exec { |entities|
    rentity = entities.find &with_id(entity.id)
    rentity.callbacks.reject!{ |c| c.endpoint_id == source_node }
  }

  # return entity
  entity
}

EVENTS_METHODS = { :subscribe_to     => subscribe_to,
                   :remove_callbacks => remove_callbacks }
end

def dispatch_manufactured_rjr_events(dispatcher)
  m = Manufactured::RJR::EVENTS_METHODS
  dispatcher.handle 'manufactured::subscribe_to',     &m[:subscribe_to]
  dispatcher.handle 'manufactured::remove_callbacks', &m[:remove_callbacks]
end
