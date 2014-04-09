# Missions Event Handler Definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event_handler'

module Missions
module EventHandlers

# Subclasses Omega::Server::EventHandler to define a custom
# event handler which accepts / runs missions dsl methods
class DSL < Omega::Server::EventHandler
  # Missions DSL callbacks registered with the event handler
  attr_accessor :missions_callbacks

  # Needed to comply w/ EventHandler interface used in omega registry
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
end # class DSL

# Missions Event Handler, allows clients to match MissionEvents
# via custom filters
class MissionEventHandler < Omega::Server::EventHandler
  # Filters which user may limit processed missions by
  FILTERS = ['mission_id', 'user_id']

  # Return bool inidicating if specified filters are valid
  def self.valid_filters?(filters)
    filters.all? { |f| FILTERS.include?(f) }
  end

  # Mission id to match
  attr_accessor :mission_id

  # Mission assigned to user to match
  attr_accessor :user_id

  def initialize(args = {})
    attr_from_args args, :mission_id => nil,
                         :user_id    => nil
    super(args)
  end

  def matches?(mission_event)
     mission_event.kind_of?(Missions::Events::MissionEvent) &&
    (mission_id.nil? || mission_event.mission.id == mission_id ) &&
    (user_id.nil?    || mission_event.mission.assigned_to_id == user_id ) &&
    super(mission_event)
  end

  def json_data
    super.merge({ :mission_id => mission_id,
                  :user_id    => user_id })
  end
end

# Manufactured Event Handler, allows clients to match Manufactured Events
# via custom filters
class ManufacturedEventHandler < Omega::Server::EventHandler
  # Manufactured event type to match
  attr_accessor :manu_event_type

  def initialize(args = {})
    attr_from_args args, :manu_event_type => nil
    super(args)
  end

  def matches?(manu_event)
     manu_event.kind_of?(Missions::Events::Manufactured) &&
    (manu_event_type.nil? || manu_event_type == manu_event.manu_event_type) &&
    super(manu_event)
  end

  def json_data
    super.merge({ :manu_event_type => manu_event_type })
  end
end

end # module EventHandlers
end # module Missions
