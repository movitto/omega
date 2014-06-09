# motel::track_movement, motel::track_rotation, motel::track_proximity,
# motel::track_stops rjr definitions
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/rjr/init'
require 'motel/rjr/track/callback_for'

module Motel::RJR
  # subscribe rjr client to location events of the specified type
  track_handler = proc { |*args|
    # location is first param, make sure it is valid
    loc_id = args.shift
    loc    = registry.entity &with_id(loc_id)
    raise DataNotFound, loc_id if loc.nil?

    # grab direct handle to registry location
    # TODO replace w/ registry.proxy_for
    rloc = registry.safe_exec { |entities| entities.find &with_id(loc.id) }

    # validate remaining args and generate callback
    cb = callback_for(@rjr_method, args)

    # validate persistent transport, source node, & source/session match
    require_persistent_transport!
    require_valid_source!
    validate_session_source! :registry => user_registry

    # set endpoint of callback
    cb.endpoint_id = @rjr_headers['source_node']

    # use rjr callback to send notification back to client
    cb.handler = proc{ |*args|
      loc = args.first
      err = false

      begin
        # ensure user has access to view location
        if loc.restrict_view
          require_privilege :registry => user_registry, :any =>
            [{:privilege => 'view', :entity => "location-#{loc.id}"},
             {:privilege => 'view', :entity => 'locations'}]
        end

        # XXX additional check needed to ensure user has access to proximity location
        if cb.event_type == :proximity && cb.to_location.restrict_view
          require_privilege :regitry => user_registry, :any =>
            [{:privilege => 'view', :entity => "location-#{cb.to_location.id}"},
             {:privilege => 'view', :entity => 'locations'}]
        end

        # invoke method via rjr callback notification
        @rjr_callback.notify(cb.rjr_event, loc)

      rescue Omega::PermissionError => e
        ::RJR::Logger.warn "loc #{loc.id} #{cb.rjr_event} callback permission error #{e}"
        err = true

      rescue Omega::ConnectionError => e
        ::RJR::Logger.warn "#{loc.id} #{cb.rjr_event} client disconnected"
        err = true

      rescue Exception => e
        ::RJR::Logger.warn "exception raised when invoking #{loc.id} #{cb.rjr_event} callback: #{e}"
        err = true

      ensure
        remove_callbacks_for rloc, :type     => cb.event_type,
                                   :endpoint => cb.endpoint_id  if err
      end
    }

    # delete callback on connection events
    handle_node_closed(@rjr_node) { |node|
      remove_callbacks_for registry,
        :class    => Motel::Location,
        :endpoint => node.message_headers['source_node']
    }

    # delete old callback and register new
    registry.safe_exec { |entities|
      rloc.callbacks[cb.event_type] ||= []
      remove_callbacks_for entities, :class       => Motel::Location,
                                     :id          => rloc.id,
                                     :type        => cb.event_type,
                                     :endpoint    => cb.endpoint_id
      rloc.callbacks[cb.event_type] << cb
    }

    # return nil
    nil
  }

  TRACK_METHODS = { :track_handler => track_handler }
end # module Motel::RJR

def dispatch_motel_rjr_track(dispatcher)
  m = Motel::RJR::TRACK_METHODS
  track_methods = ['motel::track_movement',  'motel::track_rotation',
                   'motel::track_proximity', 'motel::track_stops',
                   'motel::track_strategy']
  dispatcher.handle track_methods, &m[:track_handler]
end
