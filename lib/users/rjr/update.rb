# users::update_user rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/rjr/init'

module Users::RJR

update_user = proc { |user|
  # ensure user is valid
  raise ValidationError,
    user unless user.is_a?(Users::User) && user.valid?

  # lookup user in the registry
  ruser = registry.entity &with_id(user.id)

  # ensure user was found
  raise DataNotFound, user.id if ruser.nil?

  # require modify on user
  require_privilege :registry => registry, :any =>
    [{:privilege => 'modify', :entity => "user-#{user.id}"},
     {:privilege => 'modify', :entity => 'users'}]

  # filter properties not able to be set by the user
  user = filter_properties(user, :allow => [:password])

  # safely update user in registry
  registry.update(user, &with_id(ruser.id))

  # return user
  ruser
}

UPDATE_METHODS = { :update_user => update_user }

end # module Users::RJR

def dispatch_users_rjr_update(dispatcher)
  m = Users::RJR::UPDATE_METHODS
  dispatcher.handle 'users::update_user', &m[:update_user]
end
