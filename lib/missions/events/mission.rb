# Missions Base Mission Event definition
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'

module Missions
module Events

# Spawned by the local missions subsystem upon mission event
#
# Subclasses just need to define 'type'
class MissionEvent < Omega::Server::HandledEvent
  # Handle to mission that was completed
  attr_accessor :mission

  # Handle to registry to use to update mission
# FIXME registry not serialized 
  attr_accessor :registry

  # Completed Event intializer
  def initialize(args={})
    attr_from_args args, :mission => nil, :registry => nil
    id = "mission-#{mission.nil? ? nil : mission.id}-#{type}"
    super(args.merge({:id => id, :type => type.to_s}))
  end

  # subclasses should override
  def type
    'event'
  end

  def event_args
    [mission]
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:mission => @mission}
    }.to_json(*a)
  end

  protected

  # Helper to update mission in registry
  def update_mission
    registry.update(mission) { |m| m.id == mission.id }
  end

end # class Mission
end # module Events
end # module Missions
