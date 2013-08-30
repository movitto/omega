# users rjr inspect module
#
# Only included in debugging mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO
# - number of completed and pending user registrations
# - # of times a specified user was updated

def dispatch_users_rjr_inspect(dispatcher)
  dispatcher.handle "users::status" do
    roles = {}
    registry.entities { |e| e.is_a?(Users::User) }.
             each { |u| u.roles.each { |r|
               roles[r.id] ||= {:users => [],
                                :privileges => r.privileges.collect { |p| p.to_s }}
               roles[r.id][:users] << u.id
             }}

    {
      :users =>
        registry.entities { |e| e.is_a?(Users::User) }.size,

      :sessions =>
        registry.entities { |e| e.is_a?(Users::Session) }.
                 map { |s| [s.id, s.user.id] },

      :roles => roles
    }
  end
end
