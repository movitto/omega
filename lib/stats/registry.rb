# Static stats registry
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'stats/stat'
require 'stats/rjr/init'

module Stats

################################################################

universe_id_proc = proc {
  Stats::RJR.universe_id
}

universe_id = Stat.new(:id => :universe_id,
                       :description => 'Unique ID of the universe',
                       :generator   => universe_id_proc)

################################################################

# Return number of specified entity

num_of_proc = proc { |entity_type|
  case entity_type
  when "users" then
    Stats::RJR.node.invoke('users::get_entities', 'of_type', 'Users::User').size

  when "entities" then
    Stats::RJR.node.invoke('manufactured::get_entities').size

  when "ships" then
    Stats::RJR.node.invoke('manufactured::get_entities',
                      'of_type', 'Manufactured::Ship').size

  when "stations" then
    Stats::RJR.node.invoke('manufactured::get_entities',
                      'of_type', 'Manufactured::Station').size

  when "galaxies" then
    Stats::RJR.node.invoke('cosmos::get_entities',
                      'of_type', 'Cosmos::Entities::Galaxy').size

  when "solar_systems" then
    Stats::RJR.node.invoke('cosmos::get_entities',
                      'of_type', 'Cosmos::Entities::SolarSystem').size

  when "planets" then
    Stats::RJR.node.invoke('cosmos::get_entities',
                      'of_type', 'Cosmos::Entities::Planet').size

  when "missions" then
    Stats::RJR.node.invoke('missions::get_missions').size

  else
    nil
  end
}

num_of = Stat.new(:id => :num_of,
                  :description => 'Total number of entities',
                  :generator   => num_of_proc)

################################################################

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

################################################################

# Return list of up to <num_to_return> user ids sorted in reverse
# by the number of the specified entity they are associated with
users_with_least_proc = proc { |entity_type, num_to_return|
  user_ids = []
  case entity_type
  when "times_killed" then
    # TODO also users w/out attribute (put at front of list / or
    #   autogenerate some attrs on user creation)
    uattr = Users::Attributes::UserShipsDestroyed.id
    user_ids =
      Stats::RJR.node.invoke('users::get_entities').
            select  { |u| u.has_attribute?(uattr) }.compact.
            sort_by { |u|
              u.attributes.find { |a|
                a.type.id == uattr
              }.level
            }.reverse.collect { |u| u.id }
  end

  num_to_return ||= user_ids.size

  # return
  user_ids[0...num_to_return]
}

users_with_least = Stat.new(:id => :users_with_least,
                      :description => 'Users w/ the least entities',
                      :generator => users_with_least_proc)

################################################################

# Return list of up to <num_to_return> system ids sorted
# by the number of the specified entity they are associated with

systems_with_most_proc = proc { |entity_type, num_to_return|
  system_ids = []

  case entity_type
  # sort cosmos systems by # of entities in them
  when "entities" then
    all_systems =
      Stats::RJR.node.invoke('cosmos::get_entities',
                             'of_type', 'Cosmos::Entities::SolarSystem',
                             'children', false).
      collect { |s| s.id }

    system_ids =
      Stats::RJR.node.invoke('manufactured::get_entities').
              inject(Hash.new(0)) { |h,e|
                 h[e.system_id] += 1; h
              }.sort_by { |k,v| v }.reverse.
              collect { |e| e.first }

    # append the systems w/ 0 entities
    all_systems -= system_ids
    system_ids  += all_systems

  end

  num_to_return ||= system_ids.size

  # return
  system_ids[0...num_to_return]
}

systems_with_most = Stat.new(:id => :systems_with_most,
                      :description => 'Systems w/ the most entities',
                      :generator => systems_with_most_proc)


################################################################

STATISTICS = [universe_id, num_of, users_with_most, users_with_least, systems_with_most]

def  self.get_stat(id)
  STATISTICS.find { |s| s.id.to_s == id.to_s}
end

end # module Stats
