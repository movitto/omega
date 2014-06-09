# Omega Server Handled Event definition
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'

module Omega
module Server
  # Event with built in handler
  class HandledEvent < Event
    def initialize(args = {})
      super(args)

      @handlers.unshift proc { |e| handle_event }
    end

    private

    # Handle event, override to define custom event handler
    def handle_event
    end

    public

    # Omit locally managed handler from handlers
    def handlers_json
      {:handlers => handlers[1..-1]}
    end
  end # class HandledEvent
end # module Server
end # module Omega
