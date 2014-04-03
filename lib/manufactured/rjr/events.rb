# manufactured::subscribe_to, manufactured::remove_callbacks,
# manufactured::unsubscribe rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/common'
require 'manufactured/event_handler'
require 'manufactured/rjr/init'

module Manufactured::RJR

# Bool indicating if specified event is in manufactured events namespace
# TODO move to omega server dsl (?)
def subsystem_event?(event_type)
  Manufactured::Events.module_classes.any? { |evnt_class|
    evnt_class::TYPE.to_s == event_type.to_s
  }
end

# Bool indicating if specified entity is a subsystem entity.
# *note* right now we're not considering Loot to be here as those
# entities shouldn't be processed here
def subsystem_entity?(entity)
  entity.is_a?(Ship) || entity.is_a?(Station)
end

# Bool indicating if specified entity is a cosmos subsystem entity
def cosmos_entity?(entity)
  Cosmos::Entities.module_classes.any? { |cl| entity.is_a?(cl) }
end

def subscribe_to_subsystem_event(event_type, endpoint_id, *event_args)
  handler = Manufactured::EventHandler.new :event_type  => event_type,
                                           :endpoint_id => endpoint_id,
                                           :event_args  => event_args,
                                           :persist     => true
  handler.exec do |manu_event|
    err,err_msg = false,nil
    begin
      # run through event args, running permission
      # checks on restricted entities
      # XXX hacky, would be nice to do this in a more structured manner
      manu_event.event_args.each { |arg|
        if subsystem_entity?(arg)
          require_privilege :registry  => user_registry, :any =>
            [{:privilege => 'view', :entity => "manufactured_entity-#{arg.id}"},
             {:privilege => 'view', :entity => 'manufactured_entities'}]
        elsif cosmos_entity?(arg)
          require_privilege :registry  => user_registry, :any =>
            [{:privilege => 'view', :entity => "cosmos_entity-#{arg.id}"},
             {:privilege => 'view', :entity => 'cosmos_entities'}]
        elsif arg.is_a?(Motel::Location)
          require_privilege :registry  => user_registry, :any =>
            [{:privilege => 'view', :entity => "location-#{arg.id}"},
             {:privilege => 'view', :entity => 'locations'}] if arg.restrict_view
        end
      }

      @rjr_callback.notify 'manufactured::event_occurred',
                            event_type, *manu_event.event_args

    rescue Omega::PermissionError => e
          err = true
      err_msg = "manufactured event #{event_type} " \
                "handler permission error #{e}"

    rescue Omega::ConnectionError => e
          err = true
      err_msg = "manufactured event #{event_type} " \
                "client disconnected #{e}"

    rescue Exception => e
          err = true
      err_msg = "exception during manufactured #{event_type} " \
                "callback #{e} #{e.backtrace}"

    ensure
      if err
        ::RJR::Logger.warn err_msg
        delete_event_handler_for(:event_type  => event_type,
                                 :endpoint_id => endpoint_id,
                                 :registry    => registry)
      end
    end
  end

  # registry event handler checks ensures endpoint/event_type uniqueness
  registry << handler

  nil
end

def subscribe_to_entity_event(entity_id, event_type, endpoint_id)
  cb = Omega::Server::Callback.new :event_type  => event_type,
                                   :endpoint_id => endpoint_id,
                                   :rjr_event => 'manufactured::event_occurred'
  cb.handler = proc { |entity, *args|
    err = false

    begin
      # ensure user has access to view entity
      require_privilege :registry => user_registry, :any =>
        [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
         {:privilege => 'view', :entity => 'manufactured_entities'}]

      # invoke method via rjr callback notification
      #
      # args does not include event/entity at this point, just simply has any
      # remaining event arguments
      #
      # XXX args transformation between server callbacks being
      # invoked (in manufactured::commands) and here is somewhat
      # convoluted, would be nice to simplify
      @rjr_callback.notify 'manufactured::event_occurred', event_type, entity, *args

    rescue Omega::PermissionError => e
      ::RJR::Logger.warn "entity #{entity.id} callback permission error #{e}"
      err = true

    rescue Omega::ConnectionError => e
      ::RJR::Logger.warn "entity #{entity.id} client disconnected #{e}"
      err = true
      # also entity.callbacks associated w/ @rjr_headers['session_id'] ?

    rescue Exception => e
      ::RJR::Logger.warn "exception during #{entity.id} callback #{e} #{e.backtrace}"
      err = true

    ensure
      remove_callbacks_for entity, :type     => event_type,
                                   :endpoint => endpoint_id   if err
    end
  }

  registry.safe_exec { |entities|
    rentity = entities.find &with_id(entity_id)

    # important need to atomically delete callbacks w/ same endpoint_id:
    remove_callbacks_for entities, :class    => rentity.class,
                                   :id       => rentity.id,
                                   :type     => cb.event_type,
                                   :endpoint => cb.endpoint_id
    rentity.callbacks << cb
  }

  nil
end

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
    raise DataNotFound, entity_id unless subsystem_entity?(entity)

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

# remove callbacks registered for entity
remove_callbacks = proc { |*args|
  # verify source node / session endpoint match
  require_valid_source!
  validate_session_source! :registry => user_registry
  source_node = @rjr_headers['source_node']

  raise ArgumentError if args.empty?

  if subsystem_event?(args.first)
    event_type = args.first
    delete_event_handler_for :event_type  => event_type,
                             :endpoint_id => source_node,
                             :registry    => registry
  else
    entity_id = args.first

    # retrieve/validate entity
    entity = registry.entity &with_id(entity_id)
    raise DataNotFound, entity_id unless subsystem_entity?(entity)

    # require view on entity
    require_privilege :registry => user_registry, :any =>
      [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
       {:privilege => 'view', :entity => 'manufactured_entities'}]

    # remove callbacks from registry entity
    remove_callbacks_for registry, :id       => entity_id,
                                   :class    => entity.class,
                                   :endpoint => source_node
  end

  # return nil
  nil
}

EVENTS_METHODS = { :subscribe_to     => subscribe_to,
                   :remove_callbacks => remove_callbacks }
end

def dispatch_manufactured_rjr_events(dispatcher)
  m = Manufactured::RJR::EVENTS_METHODS
  dispatcher.handle 'manufactured::subscribe_to',     &m[:subscribe_to]
  dispatcher.handle ['manufactured::remove_callbacks', 'manufactured::unsubscribe'],
                     &m[:remove_callbacks]
end
