# [motel::track_movement,motel::track_rotation,
#  motel::track_proximity, motel::track_stops],
#  motel::remove_callbacks rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

track_methods =
  ['motel::track_movement',  'motel::track_rotation',
   'motel::track_proximity', 'motel::track_stops']

# Helper to generate a new callback from the specified method & args.
# Will validate arguments in the context of their method
def cb_from_args(rjr_method, args)
  case rjr_method
  when "motel::track_movement"
    d = args.shift
    raise ArgumentError, "distance must be >0" unless d.numeric? && d.to_f > 0
    Callbacks::Movement.new :min_distance => d.to_f,
                            :rjr_event    => 'motel::on_movement',
                            :event_type   => :movement

  when 'motel::track_rotation'
    r = args.shift
    raise ArgumentError,
      "rotation must >0 && <4*PI" unless r.numeric? &&
                                         r.to_f > 0 &&
                                         (0...4*Math::PI).include?(r.to_f)

    Callbacks::Rotation.new :min_rotation => r.to_f,
                            :rjr_event    => 'motel::on_rotation',
                            :event_type   => :rotation
                             
  when :proximity
    olid = args.shift
    oloc = Registry.instance.entities { |l| l.id == olid }.first
    raise Omega::DataNotFound, "loc specified by #{olid} not found" if oloc.nil?

    pevent = args.shift
    vevent = ['proximity', 'entered_proximity', 'left_proximity']
    raise ArgumentError,
      "event must be one of #{vevents.join(", ")}" unless vevents.include?(pevent)

    d = args.shift
    raise ArgumentError,
      "dist must be >0" unless d.numeric? && d.to_f > 0

    Callbacks::Proximity.new :max_distance => d.to_f,
                             :to_location  => oloc,
                             :rjr_event    => 'motel::on_proximity',
                             :event_type   => :proximity
                              
  when 'motel::track_stops'
    Callbacks::Stopped.new :rjr_event   => 'motel::location_stopped'.
                           :event_type  => :stopped

  #when :strategy
  # TODO changed strategy callback
  end
end

# subscribe rjr client to location events of the specified type
track_handler = proc { |*args|
  # location is first param, make sure it is valid
  loc_id = args.shift
  loc    = Registry.entities { |l| l.id == loc_id }.first
  raise DataNotFound, loc_id if loc.nil?

  # TODO verify request is coming from
  # authenticated source node which current connection
  # was established on and ensure that rjr_node_type
  # supports persistant connections

  # validate remaining args and generate callback
  cb = cb_from_args(@rjr_method, args)

  # set endpoint of callback
  cb.endpoint_id = @headers['source_node']

  # use rjr callback to send notification back to client
  cb.handler = proc{ |*args|
    loc = args.first

    begin
      # ensure user has access to view location
      if loc.restrict_view
        require_privilege \
          :any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                   {:privilege => 'view', :entity => 'locations'}])
      end

      # XXX additional check needed to ensure user has access to proximity location
      if cb.event_type == :proximity && cb.to_location.restrict_view
        require_privilege \
          :any => [{:privilege => 'view', :entity => "location-#{cb.to_location.id}"},
                   {:privilege => 'view', :entity => 'locations'}]
      end

      @rjr_callback.notify(cb.rjr_event, loc)

    rescue Omega::PermissionError => e
      RJR::Logger.warn "loc #{loc.id} #{cb.rjr_event} callback permission error #{e}"
      loc.callbacks[cb.event_type].delete cb

    rescue RJR::Errors::ConnectionError => e
      RJR::Logger.warn "#{loc.id} #{cb.rjr_event} client disconnected"
      loc.callbacks[cb.event_type].delete cb

    rescue Exception => e
      RJR::Logger.warn "exception raised when invoking #{loc.id} #{cb.rjr_event} callback: #{e}"
      loc.callbacks[cb.event_type].delete cb
    end
  }

  # delete callback on connection events
  @rjr_node.on(:closed){ |node|
    Registry.instance.safely_run {
      loc.callbacks[cb.event_type].delete(cb)
    }
  }

  # delete old callback and register new
  Registry.instance.safely_run {
    old = loc.callbacks[cb.event_type].find { |m| m.endpoint_id == cb.endpoint_id }
    loc.callbacks[cb.event_type].delete(old) unless old.nil?
    loc.callbacks[cb.event_type] << cb
  }

  # return location
  loc
}

# remove callbacks (of optional type)
remove_callbacks = proc { |*args|
  # location is first param, make sure it is valid
  loc_id  = args[0]
  loc = Registry.instance.entities { |l| l.id == loc_id }.first
  raise Omega::DataNotFound,
    "location specified by #{loc_id} not found" if loc.nil?

  # ensure user has view access on locaiton
  require_privilege \
    :any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
             {:privilege => 'view', :entity => 'locations'}]

  # if set, callback type to remove will be other param
  cb_type = args.length > 1 ? args[1] : nil
  unless cb_type.nil? || Registry::LOCATION_EVENTS.include?(cb_type)
    raise ArgumentError,
      "callback_type must be nil or one of #{Registry::LOCATION_EVENTS.join(', ')}"
  end

  # TODO verify request is coming from
  # authenticated source node which current connection
  # was established on
  source_node = @headers['source_node']

  # remove callback of the specified type or of all types
  Motel::Runner.instance.safely_run {
    if cb_type.nil?
      loc.callbacks[cb_type].reject!{ |mc| mc.endpoint_id == source_node }

    else
      loc.callbacks.reject!{ |e,mc| mc.endpoint_id == source_node }

    end

  }

  # return location
  loc
}

def dispatch_track(dispatcher)
  dispatcher.handle track_methods, &track_handler
  dispatcher.handle 'motel::remove_callbacks', &remove_callbacks
end
