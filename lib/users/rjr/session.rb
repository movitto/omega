# users::login, users::logout rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/rjr/init'

module Users::RJR

# Login the specified user
login = proc { |user|
  # ensure a valid user was specified
  raise ValidationError, user unless user.is_a?(Users::User)

  # retrieve user from registry
  ruser = registry.entity &with_id(user.id)

  # ensure user can be found
  raise DataNotFound, user.id if ruser.nil?

  session = nil

  # validate login
  if registry.valid_login?(user.id, user.password)
    # create the session
    session = registry.create_session(ruser)

    # TODO store the rjr node which this user session was
    # established on for use in other handlers

  # else raise error
  else
    raise ArgumentError, "invalid user"
  end

  # return session
  session
}

# Logout the specified session
logout = proc { |session_id|
  # Retrieve session corresponding to id
  session = registry.entity &with_id(session_id)

  # ensure session was found
  raise DataNotFound, session_id if session.nil?

  # retrieve user corresponding to session
  user = registry.entity &with_id(session.user.id)
  # assert !user.nil?

  # require modify on the user
  require_privilege :registry => registry, :any =>
    [{:privilege => 'modify', :entity => "user-#{user.id}"},
     {:privilege => 'modify', :entity => 'users'}]

  # Destroy the sesion
  registry.destroy_session(:session_id => session_id)

  # return nil
  nil
}

SESSION_METHODS = { :login  => login,
                    :logout => logout}

end # module Users::RJR

def dispatch_users_rjr_session(dispatcher)
  m = Users::RJR::SESSION_METHODS
  dispatcher.handle 'users::login',  &m[:login]
  dispatcher.handle 'users::logout', &m[:logout]
end
