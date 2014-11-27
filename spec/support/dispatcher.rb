# Omega Spec Dispatcher Helper
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# Helper method to dispatch server methods to handlers
def dispatch_to(server, rjr_module, dispatcher_id)
  server.extend(rjr_module)
  dispatcher = rjr_module.const_get(dispatcher_id)
  dispatcher.keys.each { |mid|
    server.eigenclass.send(:define_method, mid, &dispatcher[mid])
  }
end

# Helper method to setup manufactured subsystem
def setup_manufactured(dispatch_methods=nil, login_user=nil)
  dispatch_to @s, Manufactured::RJR,
                   dispatch_methods  unless dispatch_methods.nil?
  @registry = Manufactured::RJR.registry

  @login_user = login_user.nil? ? create(:user) : login_user
  @login_role = 'user_role_' + @login_user.id
  session_id @s.login(@n, @login_user.id, @login_user.password).id

  # add users, motel, and cosmos modules, initialze manu module
  @n.dispatcher.add_module('motel/rjr/init')
  @n.dispatcher.add_module('cosmos/rjr/init')
  dispatch_manufactured_rjr_init(@n.dispatcher)
end

# Helper to set rjr header
def set_header(header, value)
  @n.message_headers[header] = value
  h = @s.instance_variable_get(:@rjr_headers) || {}
  h[header] = value
  @s.instance_variable_set(:@rjr_headers, h)
end

# Helper to set session id
def session_id(id)
  id = id.id if id.is_a?(Users::Session)
  set_header 'session_id', id
end

# Helper to set source node
def source_node(source_node)
  source_node = source_node.endpoint_id if source_node.is_a?(Users::Session)
  set_header 'source_node', source_node
end

# Helper to wait for notification
#
# XXX local node notifications are processed w/ a thread which
#     notify does not join before returning, need to give thread
#     time to run (come up w/ better way todo this)
def wait_for_notify
  sleep 0.5
end
