# Omega Server Callback definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
module Server

# Base Omega Callback, through which a specified handler may
# be invoked on certain conditions.
class Callback
  # Callable to determine if callback handler should be invoked
  attr_accessor :only_if

  # Callable object to be invoked upon callback event
  # TODO make handler an array of handlers
  attr_accessor :handler

  # RJR Node Endpoint which this callback is registered for
  attr_accessor :endpoint_id

  # The event which this callback should be registered for
  attr_accessor :event_type

  # JSON-RPC method on client which is invoked by this callback
  attr_accessor :rjr_event

  # Omega::Server::Callback initializer
  #
  # @param [Hash] args hash of options to initialize callback with
  # @option args [Callable] :only_if,'only_if' procedure to use to check handling conditions
  # @option args [Callable] :handler,'handler' handler to invoke on the event
  # @option args [Callable] &block block parameter used as handler if specified
  # @option args [String]   :endpoint_id,'endpoint_id' endpoint_id registering this callback
  # @option args [String]   :rjr_event, 'rjr_event' event which callback handler should invoke
  # @option args [String]   :event_type, 'event_type' which this callback represents
  def initialize(args = {}, &block)
    attr_from_args args, :only_if      => proc { true },
                         :handler      => block,
                         :endpoint_id  => nil,
                         :event_type   => nil,
                         :rjr_event    => nil
  end

  # Return bool indicating if handler should be run
  def should_invoke?(*args)
    only_if.call *args
  end

  # Invoke the registered handler w/ the specified args
  #
  # @param [Array] args catch-all array of args to invoke handler with
  def invoke(*args)
    handler.call *args
  end

end # class Callback
end # module Server
end # module Omega
