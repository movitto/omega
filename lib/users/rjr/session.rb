# users::login, users::logout rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

users_login = proc { |user|
  raise ArgumentError, "user must be an instance of Users::User" unless user.is_a?(Users::User)
  session = nil
  user_entity = Users::Registry.instance.find(:id => user.id).first
  raise Omega::DataNotFound, "user specified by id #{user.id} not found" if user_entity.nil?
  if user_entity.valid_login?(user.id, user.password)
    # TODO store the rjr node which this user session was established on for use in other handlers
    session = Users::Registry.instance.create_session(user_entity)
  else
    raise ArgumentError, "invalid user"
  end

  session
}

users_logout = proc { |session_id|
  user = Users::Registry.instance.find(:session_id => session_id).first
  raise Omega::DataNotFound, "user specified by session_id #{session_id} not found" if user.nil?
  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user.id}"},
                                             {:privilege => 'modify', :entity => 'users'}],
                                    :session   => @headers['session_id'])

  Users::Registry.instance.destroy_session(:session_id => session_id)
  nil
}

def dispatch_session(dispatcher)
  dispatcher.handle 'users::login', &users_login
  dispatcher.handle 'users::logout', &users_logout
end
