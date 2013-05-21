# missions::create_event, missions::create_mission rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

create_event = proc { |event|
  Users::Registry.require_privilege(:privilege => 'create', :entity => 'mission_events',
                                    :session   => @headers['session_id'])

  raise ArgumentError, "Invalid #{event.class} event specified, must be Missions::Event subclass" unless event.kind_of?(Missions::Event)
  # TODO err if existing event w/ duplicate id ?

  revent = Missions::Registry.instance.create event
  revent
}

create_mission = proc { |mission|
  # XXX be very careful who can do this as missions currently use SProcs
  # to evaluate arbitrary ruby code
  Users::Registry.require_privilege(:privilege => 'create', :entity => 'missions',
                                    :session   => @headers['session_id'])

  raise ArgumentError, "Invalid #{mission.class} mission specified, must be Missions::Mission subclass" unless mission.kind_of?(Missions::Mission)
  # TODO err if existing mission w/ duplicate id ?

  # set creator user,
  # could possibly go into missions model
  creator = mission.creator_user_id.nil? ?
    Users::Registry.current_user(:session => @headers['session_id']) :
    @@local_node.invoke_request('users::get_entity', 'with_id', mission.creator_user_id)
  mission.creator_user    = creator
  mission.creator_user_id = creator.id

  rmission = Missions::Registry.instance.create mission
  rmission.node = @@local_node
  rmission
}

def dispatch_create(dispatcher)
  dispatcher.handle 'missions::create_event',   &create_event
  dispatcher.handle 'missions::create_mission', &create_mission
end
