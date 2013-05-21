# [missions::get_missions, missions::get_mission] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

get_missions = proc { |*args|
  return_first = false
  missions =
    Missions::Registry.instance.missions.select { |m|
       privs = [{:privilege => 'view', :entity => 'missions'},
                {:privilege => 'view', :entity => "mission-#{m.id}"}]
       privs << {:privilege => 'view', :entity => 'unassigned_missions'} if m.assigned_to_id.nil?
       Users::Registry.check_privilege(:any => privs,
                                       :session   => @headers['session_id'])
    }

  while qualifier = args.shift
    raise ArgumentError, "invalid qualifier #{qualifier}" unless ["with_id", "assignable_to", "assigned_to", 'is_active'].include?(qualifier)
    val = args.shift
    raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
    missions.select! { |m|
      case qualifier
      when "with_id"
        return_first = true
        m.id == val
      when "assignable_to"
        m.assignable_to?(val)
      when "assigned_to"
        return_first = true # relies on logic in assign_mission below restricting active mission assignment to one per user
        m.assigned_to?(val)
      when 'is_active'
        m.active? == val
      end
    }
  end

  return_first ? missions.first : missions
}

def dispatch_get(dispatcher)
  dispatcher.handle ['missions::get_missions', 'missions::get_mission'],
                                                          &create_event
end
