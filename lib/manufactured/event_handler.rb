# Manufactured Event Handler Definition
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'
require 'manufactured/events'

module Manufactured

# Subclasses Omega::Server::EventHandler to define a custom
# event handler with more granular event matching
class EventHandler < Omega::Server::EventHandler
  attr_accessor :event_args

  def initialize(args={})
    attr_from_args args, :event_args => []
    super(args)
  end

  def matches?(event)
    super(event) && event.trigger_handler?(self)
  end

  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       =>
        json_data.merge({:event_args => event_args})
    }.to_json(*a)
  end

end # class EventHandler
end # module Manufactured
