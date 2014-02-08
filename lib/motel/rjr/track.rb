# [motel::track_movement,motel::track_rotation,
#  motel::track_proximity, motel::track_stops],
#  motel::remove_callbacks rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/errors'
require 'rjr/common'
require 'motel/rjr/init'
require 'motel/callbacks/movement'
require 'motel/callbacks/stopped'
require 'motel/callbacks/rotation'
require 'motel/callbacks/proximity'
require 'motel/callbacks/changed_strategy'

module Motel::RJR
# Helper to generate a new callback from the specified method & args.
# Will validate arguments in the context of their method
def cb_from_args(rjr_method, args)
  case rjr_method
  when "motel::track_movement"
    d = args.shift
    raise ArgumentError, "distance must be >0" unless d.numeric? && d.to_f > 0
    Callbacks::Movement.new(:min_distance => d.to_f,
                            :rjr_event    => 'motel::on_movement',
                            :event_type   => :movement)

  when 'motel::track_rotation'
    rt = args.shift
    raise ArgumentError,
      "#{rt} must >0 && <4*PI" unless rt.numeric? &&
                                      rt.to_f > 0 &&
                                      (0...4*Math::PI).include?(rt.to_f)

    ax = args.shift
    ay = args.shift
    az = args.shift
    raise ArgumentError,
      "rotation axis must be normalized" unless ax.nil? || ay.nil? || az.nil? ||
                                                Motel.normalized?(ax, ay, az)

    Callbacks::Rotation.new :rot_theta    => rt.to_f,
                            :axis_x       => ax,
                            :axis_y       => ay,
                            :axis_z       => az,
                            :rjr_event    => 'motel::on_rotation',
                            :event_type   => :rotation

  when 'motel::track_proximity'
    olid = args.shift
    oloc = registry.entity &with_id(olid)
    raise Omega::DataNotFound, "loc specified by #{olid} not found" if oloc.nil?

    pevent  = args.shift
    vevents = ['proximity', 'entered_proximity', 'left_proximity']
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
    Callbacks::Stopped.new :rjr_event   => 'motel::location_stopped',
                           :event_type  => :stopped

  when 'motel::track_strategy'
    Callbacks::ChangedStrategy.new :rjr_event  => 'motel::changed_strategy',
                                   :event_type => :changed_strategy

  end
end

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
  cb = cb_from_args(@rjr_method, args)

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

    rescue ::RJR::Errors::ConnectionError => e
      ::RJR::Logger.warn "#{loc.id} #{cb.rjr_event} client disconnected"
      err = true

    rescue Exception => e
      ::RJR::Logger.warn "exception raised when invoking #{loc.id} #{cb.rjr_event} callback: #{e}"
      err = true

    ensure
      remove_callbacks_for registry, :class    => Motel::Location,
                                     :id       => rloc.id,
                                     :type     => cb.event_type,
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

# remove callbacks (of optional type)
remove_callbacks = proc { |*args|
  # location is first param, make sure it is valid
  loc_id  = args[0]
  loc = registry.entities { |l| l.id == loc_id }.first
  raise Omega::DataNotFound,
    "location specified by #{loc_id} not found" if loc.nil?

  # ensure user has view access on locaiton
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'view', :entity => "location-#{loc.id}"},
     {:privilege => 'view', :entity => 'locations'}]

  # if set, callback type to remove will be other param
  cb_type = args.length > 1 ? args[1] : nil
  unless cb_type.nil? ||
         LOCATION_EVENTS.collect { |e| e.to_s }.include?(cb_type)
    raise ArgumentError,
      "callback_type must be nil or one of #{LOCATION_EVENTS.join(', ')}"
  end

  require_valid_source!
  validate_session_source! :registry => user_registry
  source_node = @rjr_headers['source_node']

  if cb_type.nil?
    remove_callbacks_for registry, :class       => Motel::Location,
                                   :id          => loc.id,
                                   :endpoint    => source_node

  else
    remove_callbacks_for registry, :class       => Motel::Location,
                                   :id          => loc.id,
                                   :type        => cb_type.intern,
                                   :endpoint    => source_node

  end

  # return location
  loc
}

TRACK_METHODS = { :track_handler    => track_handler,
                  :remove_callbacks => remove_callbacks }
end

def dispatch_motel_rjr_track(dispatcher)
  m = Motel::RJR::TRACK_METHODS
  track_methods =
    ['motel::track_movement',  'motel::track_rotation',
     'motel::track_proximity', 'motel::track_stops',
     'motel::track_strategy']

  dispatcher.handle track_methods, &m[:track_handler]
  dispatcher.handle 'motel::remove_callbacks', &m[:remove_callbacks]
end
