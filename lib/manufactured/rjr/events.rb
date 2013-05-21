# manufactured::subscribe_to, manufactured::remove_callbacks
# rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

manufactured_subscribe_to = proc { |entity_id, event|
  entity = Manufactured::Registry.instance.find(:id => entity_id).first
  raise Omega::DataNotFound, "manufactured entity specified by #{entity_id} not found" if entity.nil?

  # TODO add option to verify request is coming from authenticated source node which current connection was established on
  # TODO ensure that rjr_node_type supports persistant connections

  event_callback =
    Callback.new(event, :endpoint => @headers['source_node']){ |*args|
      begin
        Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                   {:privilege => 'view', :entity => 'manufactured_entities'}],
                                          :session => @headers['session_id'])
        @rjr_callback.invoke 'manufactured::event_occurred', *args

      rescue Omega::PermissionError => e
        # FIXME delete all entity.notification_callbacks associated w/ @headers['session_id']
        RJR::Logger.warn "client does not have privilege to subscribe to #{event} on #{entity.id}"
        entity.notification_callbacks.delete event_callback

      # FIXME @rjr_node.on(:closed){ |node| entity.notification_callbacks.delete event_callback }
      rescue RJR::Errors::ConnectionError => e
        RJR::Logger.warn "subscribe_to client disconnected"
        entity.notification_callbacks.delete event_callback
      end
    }

  Manufactured::Registry.instance.safely_run {
    old = entity.notification_callbacks.find { |n| n.type == event_callback.type &&
                                                   n.endpoint_id == event_callback.endpoint_id }

    unless old.nil?
     entity.notification_callbacks.delete(old)
    end

    entity.notification_callbacks << event_callback
  }

  entity
}

manufactured_remove_callbacks = proc { |entity_id|
  source_node = @headers['source_node']
  # TODO add option to verify request is coming from authenticated source node which current connection was established on

  entity = Manufactured::Registry.instance.find(:id => entity_id, :include_graveyard => true).first
  raise Omega::DataNotFound, "entity specified by #{entity_id} not found" if entity.nil?
  Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                             {:privilege => 'view', :entity => 'manufactured_entities'}],
                                    :session => @headers['session_id'])

  Manufactured::Registry.instance.safely_run {
    entity.notification_callbacks.reject!{ |nc| nc.endpoint_id == source_node }
  }

  entity
}

def dispatch_events(dispatcher)
  dispatcher.handle 'manufactured::subscribe_to',
                      &manufactured_subscribe_to
  dispatcher.handle 'manufactured::remove_callbacks',
                      &manufactured_remove_callbacks
end
