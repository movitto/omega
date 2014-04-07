# manufactured::subscribe_to subsystem_event helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/event_handler'
require 'manufactured/rjr/subscribe_to/helpers'

module Manufactured::RJR
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
end # module Manufactured::RJR
