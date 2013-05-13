# Static stats registry
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Stats

# Primary server side entity tracker for stats.
#
# Currently all stats supported by the project are just defined here,
# we may want to change this in the future
#
# Singleton class, access via Manufactured::Registry.instance.
class Registry
  include Singleton

  # rjr node used to communicate w/ other subsystems
  attr_accessor :node

  # actual stats
  attr_accessor :stats

  # get stat w/ the specified id
  def get(stat_id)
    @stats.find { |s| s.id.to_s == stat_id.to_s }
  end

  def init
    @stats = []

    [  ######################### stats

       # Return number of specified entity
       Stat.new(:id => :num_of,
                :description => 'Total number of entities',
                :generator =>
           proc { |entity_type|
              case entity_type
              when "users" then
                Registry.instance.node.invoke_request('users::get_entities',
                                                      'of_type', 'Users::User').size

              when "entities" then
                Registry.instance.node.invoke_request('manufactured::get_entities').size

              when "ships" then
                Registry.instance.node.invoke_request('manufactured::get_entities',
                                                      'of_type', 'Manufactured::Ship').size

              when "stations" then
                Registry.instance.node.invoke_request('manufactured::get_entities',
                                                      'of_type', 'Manufactured::Station').size

              when "galaxies" then
                Registry.instance.node.invoke_request('cosmos::get_entities',
                                                      'of_type', 'Cosmos::Galaxy').size

              when "solar_systems" then
                Registry.instance.node.invoke_request('cosmos::get_entities',
                                                      'of_type', 'Cosmos::SolarSystem').size

              when "planets" then
                Registry.instance.node.invoke_request('cosmos::get_entities',
                                                      'of_type', 'Cosmos::Planet').size

              when "missions" then
                Registry.instance.node.invoke_request('missions::get_missions').size

              else
                nil
              end
           }),

       # Return list of up to <num_to_return> user ids sorted
       # by the number of the specified entity they are associated with
       Stat.new(:id => :with_most,
                :description => 'Users w/ the most entities',
                :generator =>
           proc { |entity_type, num_to_return|
             user_ids = []

             case entity_type
             when "entities" then
               # count entities per user sort
               user_ids =
                 Registry.instance.node.
                          invoke_request('manufactured::get_entities').
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
                 Registry.instance.node.
                          invoke_request('users::get_entities').
                          sort_by { |u|
                            u.attribute.find { |a|
                              a.type.id == attr_map[entity_type]
                            }.level
                          }

             when "missions_completed" then
               user_ids =
                 Registry.instance.node.
                          invoke_request('missions::get_missions', 'is_active', false).
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
           }),

       # Return list of up to <num_to_return> user ids sorted in reverse
       # by the number of the specified entity they are associated with
       Stat.new(:id => :with_least,
                :description => 'Users w/ the least entities',
                :generator =>
           proc { |entity_type, num_to_return|
             user_ids = []
             case entity_type
             when "times_killed" then
               user_ids =
                 Registry.instance.node.
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
           });


       # TODO ownership of systems/empires, others ...

    ].each { |s| @stats << s }
  end
end

end
