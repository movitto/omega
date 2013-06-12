# missions::assign_mission rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'missions/rjr/init'

module Missions::RJR

# Assign mission to user
assign_mission = proc { |mission_id, user_id|
  # retrieve mission from registry
  mission = registry.entity &with_id(mission_id)
  raise ArgumentError, mission_id if mission.nil?

  # retrieve user from server
  # if problems retrieving, raise argument error
  user = 
    begin node.invoke('users::get_entity', 'with_id', user_id)
    rescue Exception => e ; raise ArgumentError, user_id end

  # require modify user
  require_privilege :registry => user_registry, :any =>
                   [{:privilege => 'modify', :entity => 'users'},
                    {:privilege => 'modify', :entity => "user-#{user.id}"}]

  # TODO require modify missions here ?
  #require_privilege :registry => user_registry,
  #                  :privilege => 'modify',
  #                  :entity => 'missions'

  # retrieve missions assigned to user and those that are active
  missions = registry.entities { |m| m.is_a?(Mission) && m.assigned_to?(user) }
  active   = missions.select   { |m| m.active? }

  # right now do not allow users to be assigned to more
  # than one mission at a time
  # TODO incorporate MissionAgent attribute allowing user
  # to accept > 1 mission at a time
  raise OperationError, "#{user_id} has an active mission" unless active.empty?

  registry.safe_exec {
    # ensure mission is assignable to user
    raise OperationError,
          "#{mission_id} not assignable to user" unless mission.assignable_to?(user)

    # XXX get registry mission
    rmission = registry.instance_variable_get(:@entities).find &with_id(mission.id)

    # assign mission to user
    rmission.assign_to user
  }

  # return mission
  mission
}

ASSIGN_METHODS = { :assign_mission => assign_mission }
end

def dispatch_missions_rjr_assign(dispatcher)
  m = Missions::RJR::ASSIGN_METHODS
  dispatcher.handle 'missions::assign_mission', &m[:assign_mission]
  #dispatcher.handle('missions::unassign_mission', '...' # TODO ?
end
