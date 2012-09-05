# Manufactured callback definitions
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured

# Base Manufactured callback, provides mechanism to register
# a callback handler for the specified manufactured event.
class Callback
  # Type of callback, the manufactured event on which to trigger the handler
  attr_accessor :type

  # Callable object to be invoked upon event
  attr_accessor :handler

  # ID of RJR endpoint (node) which registered this callback
  attr_accessor :endpoint_id

  # Callback initializer
  #
  # @param [String] type type of manufactured event on which this callback should be triggered
  # @param [Hash] args hash of options to initialize callback with
  # @option args [String] :endpoint,'endpoint' endpoint registering this callback
  # @option args [Callable] :handler,'handler' handler to invoke on the event
  # @param [Callable] block handler to invoke on the event
  def initialize(type, args = {}, &block)
    @type    = type.is_a?(Symbol)? type : type.intern
    @handler = args[:handler] if args.has_key?(:handler)
    @handler = block if block_given?

    @endpoint_id = args[:endpoint] || args['endpoint']
  end

  # Invoke the callcack handler w/ the specified args
  def invoke(*args)
    handler.call *args
  end

  # Convert callback to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        { :type => @type, :endpoint => @endpoint_id}
    }.to_json(*a)
  end

  # Create new callback from json representation
  def self.json_create(o)
    callback = new(o['data']['type'], o['data'])
    return callback
  end

end

end # module Manufactured
