# users_with_most stat
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Stats
  # Return list of up to <num_to_return> user ids sorted
  # by the number of the specified entity they are associated with
  
  users_with_most_proc = proc { |entity_type, num_to_return|
    user_ids = []
  
    case entity_type
    when "entities" then
      # count entities per user sort
      user_ids =
        Stats::RJR.node.invoke('manufactured::get_entities').
                inject(Hash.new(0)) { |h,e|
                   h[e.user_id] += 1; h
                }.sort_by { |k,v| v }.reverse.
                collect { |e| e.first }
  
    when "kills",
         "times_killed",
         "resources_collected",
         "loot_collected",
         "distance_moved"
      attr_map = {
        'kills'               => Users::Attributes::ShipsUserDestroyed.id,
        'times_killed'        => Users::Attributes::UserShipsDestroyed.id,
        'resources_collected' => Users::Attributes::ResourcesCollected.id,
        'loot_collected'      => Users::Attributes::LootCollected.id,
        'distance_moved'      => Users::Attributes::DistanceTravelled.id
      }
      uattr = attr_map[entity_type]
      # TODO limit request to just return users w/ the specified attribute
      user_ids =
        Stats::RJR.node.invoke('users::get_entities').
              select  { |u| u.has_attribute?(uattr) }.compact.
              sort_by { |u|
                u.attributes.find { |a|
                  a.type.id == uattr
                }.total
              }.reverse.collect { |u| u.id }
  
    when "missions_completed" then
      user_ids =
        Stats::RJR.node.invoke('missions::get_missions', 'is_active', false).
              inject(Hash.new(0)) { |h,m|
                h[m.assigned_to.id] += 1 if m.assigned_to
                h
              }.sort_by { |k,v| v }.reverse.
              collect { |e| e.first }
  
    # TODO 'diverse_entities' type
    end
  
    num_to_return ||= user_ids.size
  
    # return
    user_ids[0...num_to_return]
  }
  
  users_with_most = Stat.new(:id => :users_with_most,
                       :description => 'Users w/ the most entities',
                       :generator => users_with_most_proc)

  register_stat users_with_most
end # module Stats
