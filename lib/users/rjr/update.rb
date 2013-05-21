# users::update_user rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

update_server = proc { |user|
  raise ArgumentError, "user must be an instance of Users::User" unless user.is_a?(Users::User)

  user_entity = Users::Registry.instance.find(:id => user.id).first
  raise Omega::DataNotFound, "user specified by id #{user.id} not found" if user_entity.nil?
  Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "user-#{user.id}"},
                                             {:privilege => 'modify', :entity => 'users'}],
                                    :session   => @headers['session_id'])
  Users::Registry.instance.safely_run {
    user_entity.update!(user)
  }
  user_entity
}

def dispatch_update(dispatcher)
  dispatcher.handle 'users::update_user', &update_user
end
