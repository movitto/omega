# motel::remove_callbacks rjr definition
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/rjr/init'

module Motel::RJR
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

  REMOVE_CALLBACKS_METHODS = { :remove_callbacks => remove_callbacks }
end # module Motel::RJR

def dispatch_motel_rjr_remove_callbacks(dispatcher)
  m = Motel::RJR::REMOVE_CALLBACKS_METHODS
  dispatcher.handle 'motel::remove_callbacks', &m[:remove_callbacks]
end
