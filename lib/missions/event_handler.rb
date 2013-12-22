# Missions Event Handler Definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'

module Missions

# Subclasses Omega::Server::EventHandler to define a custom
# event handler which accepts / runs missions dsl methods
class EventHandler < Omega::Server::EventHandler
  # Missions DSL callbacks registered with the event handler
  attr_accessor :missions_callbacks
  alias :handlers :missions_callbacks

  def initialize(args={})
    attr_from_args args,
                   :missions_callbacks => []
    super(args)
  end

  def exec(cb)
    @missions_callbacks << cb
  end

  def to_json(*a)
    { 'json_class' => self.class.name,
      'data'       =>
        json_data.merge({:missions_callbacks => missions_callbacks})
    }.to_json(*a)
  end

  # Make sure to have resolved mission dsl proxies before calling invoke
  def invoke(*args)
    @missions_callbacks.each { |cb|
      cb.call *args
    }
  end
end # class EventHandler
end # module Missions
