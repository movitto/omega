# missions::create_event, missions::create_mission rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'missions/dsl'
require 'missions/rjr/init'

module Missions::RJR

# Create new event in the registry
create_event = proc { |event|
  # require create mission events
  require_privilege :registry  => user_registry,
                    :privilege => 'create',
                    :entity    => 'mission_events'

  # ensure valid event
  raise ValidationError, event unless event.kind_of?(Omega::Server::Event)

  # add to registry
  registry << event

  # TODO err if not added (existing event w/ duplicate id) ?

  # return event
  event
}

# Create new mission in the registry
create_mission = proc { |mission|
  # require create missions
  require_privilege :registry  => user_registry,
                    :privilege => 'create',
                    :entity    => 'missions'

  # ensure valid mission
  raise ValidationError, mission unless mission.kind_of?(Mission)

  # set creator user if nil
  mission.creator =
    current_user(:registry => user_registry) if mission.creator_id.nil?

  # resolve mission dsl references
  Missions::DSL::Client::Proxy.resolve(mission)

  # add mission to registry
  registry << mission

  # TODO err if not added (existing mission w/ duplicate id) ?

  # return mission
  mission
}

CREATE_METHODS = { :create_event => create_event,
                   :create_mission  => create_mission }

end # module Missions::RJR

def dispatch_missions_rjr_create(dispatcher)
  m = Missions::RJR::CREATE_METHODS
  dispatcher.handle 'missions::create_event',   &m[:create_event]
  dispatcher.handle 'missions::create_mission', &m[:create_mission]
end
