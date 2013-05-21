# missions::assign_mission rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

assign_mission = proc { |mission_id, user_id|
  mission = Missions::Registry.instance.missions.find { |m| m.id == mission_id }
  user    =  @@local_node.invoke_request('users::get_entity', 'with_id', user_id)

  raise ArgumentError, "mission with id #{mission_id} could not be found" if mission.nil?
  raise ArgumentError, "user with id #{user_id} could not be found"       if user.nil?

  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => 'users'},
                                             {:privilege => 'modify', :entity => "user-#{user.id}"}],
                                    :session   => @headers['session_id'])

  # TODO modify missions here?
  #Users::Registry.require_privilege(:privilege => 'modify', :entity => 'missions',
  #                                  :session   => @headers['session_id'])

  user_missions = Missions::Registry.instance.missions.select { |m| m.assigned_to_id == user.id }
  active        = user_missions.select { |m| m.active? }

  # right now do not allow users to be assigned to more than one mission at a time
  # TODO incorporate MissionAgent attribute allowing user to accept > 1 mission at a time
  raise Omega::OperationError, "user #{user_id} already has an active mission" unless active.empty?

  # assign mission to user and return it
  Missions::Registry.instance.safely_run {
    # raise error if not assignable to user
    raise Omega::OperationError, "mission #{mission_id} not assignable to user" unless mission.assignable_to?(user)

    mission.assign_to user
  }

  mission
}

def dispatch_assign_mission(dispatcher)
  dispatcher.handle 'missions::assign_mission', &assign_mission
  #dispatcher.handle('missions::unassign_mission', '...' # TODO ?
end
