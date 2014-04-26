# Manufactured HasCallbacks Entity Mixin
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/resource'

module Manufactured
module Entity
  module HasCallbacks
    # Callbacks to invoke on ship events
    attr_accessor :callbacks

    # Initialize callbacks from args
    def callbacks_from_args(args)
      attr_from_args args, :callbacks => []
    end

    # Run callbacks
    def run_callbacks(type, *args)
      @callbacks.select { |c| c.event_type == type }.
                 each   { |c| c.invoke self, *args  }
    end

    # Remove callbacks matching the specified args
    def remove_callbacks(args={})
      @callbacks.reject! { |cb|
        (!args.has_key?(:event_type)  || cb.event_type  == args[:event_type]) &&
        (!args.has_key?(:endpoint_id) || cb.endpoint_id == args[:endpoint_id])
      }
    end

    # Return bool indicating if callbacks are valid
    def callbacks_valid?
      @callbacks.is_a?(Array) &&
      @callbacks.select { |c| !c.kind_of?(Manufactured::Callback) }.empty?
      # && TODO ensure validity of individual callbacks
    end
  end # module HasCallbacks
end # module Entity
end # module Manufactured
