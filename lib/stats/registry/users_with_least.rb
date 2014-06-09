# users_with_least stat
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Stats
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

  register_stat users_with_least
end # module Stats
