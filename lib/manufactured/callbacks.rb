# Manufactured callback definitions
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured

# Manufactured callback, provides access to invocable handler
class Callback
  # type of callback
  attr_accessor :type

  # Accessor which will be invoked upon callback event
  attr_accessor :handler

  # endpoint_id which this callback is being used for
  attr_accessor :endpoint_id

  def initialize(type, args = {}, &block)
    @type    = type.is_a?(Symbol)? type : type.intern
    @handler = args[:handler] if args.has_key?(:handler)
    @handler = block if block_given?

    @endpoint_id = args[:endpoint] || args['endpoint']
  end

  def invoke(*args)
    handler.call *args
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        { :type => @type, :endpoint => @endpoint_id}
    }.to_json(*a)
  end

  def self.json_create(o)
    callback = new(o['data']['type'], o['data'])
    return callback
  end

end

end # module Manufactured
