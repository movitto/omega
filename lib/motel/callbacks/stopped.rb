# Motel stopped callback definition
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/callback'

module Motel
module Callbacks

# Defines a {Omega::Server::Callback} to invoke callback
# when a location stops.
#
# Simple wrapper around the callback base interface, does no requirement
# checking on its own locally
class Stopped < Omega::Server::Callback
  # Motel::Callbacks::Stopped initializer
  #
  # @param [Hash] args hash of options to initialize callback with
  def initialize(args = {}, &block)
    super(args, &block)
  end

  # Convert callback to human readable string and return it
  def to_s
    "stopped"
  end

  # Convert callback to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        { :endpoint_id => @endpoint_id }
    }.to_json(*a)
  end

  # Create new callback from json representation
  def self.json_create(o)
    new(o['data'])
  end

end # class Stopped
end # module Callbacks
end # module motel
