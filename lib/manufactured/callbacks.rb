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

  def initialize(type, args = {}, &block)
    @type    = type.is_a?(Symbol)? type : type.intern
    @handler = args[:handler] if args.has_key?(:handler)
    @handler = block if block_given?
  end

  def invoke(*args)
    handler.call *args
  end

end

end # module Manufactured
