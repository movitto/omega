# Static stats registry
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'stats/stat'

module Stats

# Internal helper, get stats node
def self.node
  @node
end

# Internal helper, set stats node
def self.node=(node)
  @node = node
  @node
end

################################################################

# Return number of specified entity

num_of_proc = proc { |entity_type|
  case entity_type
  when "users" then
    Stats.node.invoke('users::get_entities', 'of_type', 'Users::User').size

  when "entities" then
    Stats.node.invoke('manufactured::get_entities').size

  when "ships" then
    Stats.node.invoke('manufactured::get_entities',
                      'of_type', 'Manufactured::Ship').size

  when "stations" then
    Stats.node.invoke('manufactured::get_entities',
                      'of_type', 'Manufactured::Station').size

  when "galaxies" then
    Stats.node.invoke('cosmos::get_entities',
                      'of_type', 'Cosmos::Galaxy').size

  when "solar_systems" then
    Stats.node.invoke('cosmos::get_entities',
                      'of_type', 'Cosmos::SolarSystem').size

  when "planets" then
    Stats.node.invoke('cosmos::get_entities',
                      'of_type', 'Cosmos::Planet').size

  when "missions" then
    Stats.node.invoke('missions::get_missions').size

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

with_most_proc = proc { |entity_type, num_to_return|
  user_ids = []

  case entity_type
  when "entities" then
    # count entities per user sort
    user_ids =
      Stats.node.invoke('manufactured::get_entities').
              inject(Hash.new(0)) { |h,e|
                 h[e.user_id] += 1; h
              }.sort_by { |k,v| v }.reverse.
              collect { |e| e.first }

  when "kills" then
  when "times_killed" then
  when "resources_collected" then
  when "loot_collected" then
  when "distance_moved" then
    attr_map = {
      'kills'               => Users::Attributes::ShipsUserDestroyed.id,
      'times_killed'        => Users::Attributes::UserShipsDestroyed.id,
      'resources_collected' => Users::Attributes::ResourcesCollected.id,
      'loot_collect'        => Users::Attributes::LootCollected.id,
      'distance_moved'      => Users::Attributes::DistanceTravelled.id
    }
    # TODO limit request to just return users w/ the specified attribute
    user_ids =
      Stats.node.invoke('users::get_entities').
            sort_by { |u|
              u.attributes.find { |a|
                a.type.id == attr_map[entity_type]
              }.total
            }

  when "missions_completed" then
    user_ids =
      Stats.node.invoke('missions::get_missions', 'is_active', false).
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

with_most = Stat.new(:id => :with_most,
                     :description => 'Users w/ the most entities',
                     :generator => with_most_proc)

################################################################

# Return list of up to <num_to_return> user ids sorted in reverse
# by the number of the specified entity they are associated with
with_least_proc = proc { |entity_type, num_to_return|
  user_ids = []
  case entity_type
  when "times_killed" then
    user_ids =
      Stats.node.
            invoke_request('users::get_entities').
            sort_by { |u|
              u.attribute.find { |a|
                a.type.id == Users::Attributes::UserShipsDestroyed.id
              }.level
            }
  end

  num_to_return ||= user_ids.size

  # return
  user_ids[0...num_to_return]
}

with_least = Stat.new(:id => :with_least,
                      :description => 'Users w/ the least entities',
                      :generator => with_least_proc)

################################################################

STATISTICS = [num_of, with_most, with_least]

def  self.get_stat(id)
  STATISTICS.find { |s| s.id == id}
end

end # module Stats
