# manufactured::subscribe_to entity_event helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Manufactured::RJR
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
end # module Manufactured::RJR
