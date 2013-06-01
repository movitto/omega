# users::save_state, users::load_state,
# rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/rjr/init'

module Users::RJR

save_state = proc { |output|
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)
  File.open(output, 'a+') { |f| registry.save(f) }
}

restore_state = proc { |input|
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)
  File.open(input, 'r') { |f| registry.restore(f) }
}

STATE_METHODS = { :save_state => save_state, :restore_state => restore_state }

end # module Users::RJR

def dispatch_state(dispatcher)
  m = Users::RJR::STATE_METHODS
  dispatcher.handle "users::save_state",    &m[:save_state]
  dispatcher.handle "users::restore_state", &m[:restore_state]
end
