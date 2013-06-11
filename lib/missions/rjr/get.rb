# [missions::get_missions, missions::get_mission] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Missions::RJR

# Retrieve all missions in registry matching criteria
get_missions = proc { |*args|
  # retrieve missions matching filters specified by args
  filters = filters_from_args args,
    :with_id       => proc { |m,id| m.id  == id         },
    :assignable_to => proc { |m, u| m.assignable_to?(u) },
    :assigned_to   => proc { |m, u| m.assigned_to?(u)   },
    :is_active     => proc { |m, b| m.active? == b      }
  missions = registry.entities.
                      select { |m| m.is_a?(Mission) &&
                                   filters.all? { |f| f.call(m) } }

  # exclude missions which user does not have access to view
  missions.reject! { |m|
    privs = [{:privilege => 'view', :entity => 'missions'},
             {:privilege => 'view', :entity => "mission-#{m.id}"}] + 
             (m.assigned_to_id.nil? ?
               [{:privilege => 'view', :entity => 'unassigned_missions'}] : [])
    !check_privilege:registry => user_registry, :any => privs
  }


  # if id of entity or id of assigned user is specified, only return single entitiy
  return_first = args.include?('with_id') || args.include?('assigned_to')
  missions = missions.first if return_first

  # return missions
  missions
}
GET_METHODS = { :get_missions => get_missions  }

end # module Missions::RJR

def dispatch_missions_rjr_get(dispatcher)
  m = Missions::RJR::GET_METHODS
  dispatcher.handle ['missions::get_missions', 'missions::get_mission'],
                                                       &m[:get_missions]
end
