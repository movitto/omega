# users::login, users::logout rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users::RJR

# Login the specified user
login = proc { |user|
  # ensure a valid user was specified
  raise Omega::ValidationError,
    user unless user.is_a?(Users::User)

  # retrieve user from registry
  ruser =
    Registry.instance.entities { |e|
      e.id == user.id
    }.first

  # ensure user can be found
  raise DataNotFound, user.id if user.nil?

  session = nil

  # validate login
  if Registry.instance.valid_login?(user.id, user.password)
    # create the session
    session = Registry.instance.create_session(ruser)

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
  # Retrieve user corresponding to session
  user =
    Registry.instance.entities { |e|
      e.session_id == session_id
    }.first

  # ensure user was found
  raise DataNotFound, session_id if user.nil?

  # require modify on the user
  require_privilege :any =>
    [{:privilege => 'modify', :entity => "user-#{user.id}"},
     {:privilege => 'modify', :entity => 'users'}]

  # Destroy the sesion
  Registry.instance.destroy_session(:session_id => session_id)

  # return nil
  nil
}

SESSION_METHODS = { :login  => login,
                    :logout => logout}

end # module Users::RJR

def dispatch_session(dispatcher)
  m = Users::RJR::SESSION_METHODS
  dispatcher.handle 'users::login',  &m[:login]
  dispatcher.handle 'users::logout', &m[:logout]
end
