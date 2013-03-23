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
                :generator => proc { |entity_type|
                                # currently suppor users entity types
                                # TODO add support for manufactured, cosmos, missions, etc
                                case entity_type
                                when "users" then
                                  Registry.instance.node.invoke_request('users::get_entities',
                                                                        'of_type', 'Users::User').size
                                else
                                  nil
                                end
                              }),

       # Return list of up to <num_to_return> user ids sorted
       # by the number of manufactued enties the users own
       Stat.new(:id => :most_entities,
                :description => 'Users w/ the most entities',
                :generator => proc { |num_to_return|
                                # get all ships
                                entities = Registry.instance.node.invoke_request 'manufactured::get_entities'

                                # count ships per user, sort
                                eu = entities.inject(Hash.new(0)) { |h,e|
                                  h[e.user_id] += 1; h
                                }.sort_by { |k,v| v }.reverse

                                num_to_return ||= eu.size

                                # return 
                                eu[0...num_to_return].collect { |eui| eui.first }
                              }),

       # ...
       # ownership of systems/empires, others ...
       Stat.new(:id => :todo,
                :generator => proc {
                              })

    ].each { |s| @stats << s }
  end
end

end
