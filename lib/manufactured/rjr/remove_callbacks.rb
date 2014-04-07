# manufactured::remove_callbacks, manufactured::unsubscribe rjr definitions
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'

module Manufactured::RJR
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
      raise DataNotFound, entity_id unless subscribable_entity?(entity)

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

  REMOVE_CALLBACKS_METHODS = {:remove_callbacks => remove_callbacks}

end # module Manufactured::RJR

def dispatch_manufactured_rjr_remove_callbacks(dispatcher)
  m = Manufactured::RJR::REMOVE_CALLBACKS_METHODS
  dispatcher.handle ['manufactured::remove_callbacks',
                     'manufactured::unsubscribe'],
                  &m[:remove_callbacks]
end
