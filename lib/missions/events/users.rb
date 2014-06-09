# Missions Users Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'

module Missions
module Events

# An event this is spawed by another in the users subsystem
class Users < Omega::Server::Event
  # Array of args received pertaining to the users event
  attr_accessor :users_event_args

  # Needed for Event interface compatability
  alias :event_args :users_event_args

  # Users Event intializer
  def initialize(args={})
    attr_from_args args, :users_event_args => []

    # users event should be the first arg
    event = @users_event_args.first
    super(args.merge({:id => event, :timestamp => Time.now}))
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        json_data.merge({:users_event_args => @users_event_args})
    }.to_json(*a)
  end
end

end
end
