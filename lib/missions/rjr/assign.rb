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

  # XXX assignment callbacks need to be run outside of lock
  assignment_callbacks = []

  registry.safe_exec { |entities|
    # get registry mission
    rmission = entities.find &with_id(mission.id)
    assignment_callbacks = rmission.assignment_callbacks

    # ensure mission is assignable to user
    raise OperationError,
      "#{mission_id} not assignable to user" unless rmission.assignable_to?(user)

    # assign mission to user
    rmission.assign_to user

    # XXX update mission to pull in attributes required by callbacks below
    mission.update :mission => rmission
  }

  # invoke assignment callbacks
  assignment_callbacks.each { |cb|
    begin
      cb.call mission
    rescue Exception => e
      ::RJR::Logger.warn "error in mission #{mission.id} assignment: #{e}"
    end
  }

  # add permissions to view mission to owner
  # (others will now be excluded as it is assigned)
  user_role = "user_role_#{user_id}"
  node.invoke('users::add_privilege', user_role,
              "view", "mission-#{mission.id}")

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
