# Motel EventDispatcher Mixin.
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel

# Mixed into Location, provides event / callback support
module EventDispatcher
  # [Hash<String, Motel::Callback>] Callbacks to be invoked on various events
  attr_accessor :callbacks

  # Initialize default callbacks / callbacks from args
  def callbacks_from_args(args)
    attr_from_args args, :callbacks => Hash.new { |h,k| h[k] = [] }

    # convert string callback keys into symbols
    callbacks.keys.each { |k|
      # ensure string correspond's to
      # valid callback type before interning
      if k.is_a?(String)
        if LOCATION_EVENTS.collect { |e| e.to_s }.include?(k)
          callbacks[k.intern] = callbacks[k]
          callbacks.delete(k)
        else
          raise ArgumentError, "invalid callback specified"
        end
      end
    }
  end

  # Invoke callbacks for the specified event
  def raise_event(evnt, *args)
    @callbacks[evnt].each { |cb|
      cb.invoke self, *args if cb.should_invoke? self, *args
    } if @callbacks.has_key?(evnt)
  end

  # Return callbacks in json format
  def callbacks_json
    {:callbacks => callbacks}
  end
end # module EventDispatcher
end # module Motel
