# users rjr inspect module
#
# Only included in debugging mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO
# - number of completed and pending user registrations
# - # of times a specified user was updated

module Users::RJR

# retrieve status of the users subsystem
get_status = proc {
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
      Hash[*registry.entities { |e| e.is_a?(Users::Session) }.
                     collect  { |s|       [s.id, s.user.id] }.flatten],

    :roles => roles
  }
}

INSPECT_METHODS = { :get_status => get_status }
end

def dispatch_users_rjr_inspect(dispatcher)
  m = Users::RJR::INSPECT_METHODS
  dispatcher.handle "users::status", &m[:get_status]
end
