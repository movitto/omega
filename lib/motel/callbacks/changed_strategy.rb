# Motel changed strategy callback definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/callback'

module Motel
module Callbacks

# Defines a {Omega::Server::Callback} to only invoke callback if a location's
# movement strategy is changed
#
# This callback will be invoked with the current location (with new movement
# strategy) as well as the old movement strategy
#
# TODO this is only invoked when the movement strategy class changes, not
# when the strategy stays the same but attributes are updated. Would be
# nice to also support the later
class ChangedStrategy < Omega::Server::Callback
  # original strategy which to compare against
  attr_accessor :orig_ms

  protected

  def check_strategy(loc)
    # intentially leave orig_ms as nil if not explicitly
    # set before so that on first run callback is invoked
    #@orig_ms = loc.ms if @orig_ms.nil?
    loc.ms.class != @orig_ms.class
  end

  public

  # Motel::Callbacks::ChangedStrategy initializer
  #
  # @param [Hash] args hash of options to initialize callback with
  # @option args [Integer] :orig_ms,'orig_ms' original movement strategy
  def initialize(args = {}, &block)
    attr_from_args args, :orig_ms => nil

    @only_if = proc { |*args| self.check_strategy(*args) }
    super(args)
  end

  # Override {Omega::Server::Callback#invoke}, call original then update orig_ms
  def invoke(loc)
    super(loc, @orig_ms)
    @orig_ms = loc.ms
  end

  # Convert callback to human readable string and return it
  def to_s
    "(#{@orig_ms.class})"
  end

  # Convert callback to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        { :endpoint_id => @endpoint_id, :orig_ms => @orig_ms }
    }.to_json(*a)
  end

  def self.json_create(o)
    callback = new(o['data'])
    return callback
  end
end # class ChangedStrategy

end # module Callbacks
end # module Motel
