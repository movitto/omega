# motel::save_state, motel::load_state definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/rjr/init'

module Motel::RJR
# save state of motel subsystem
save_state = proc { |output|
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)
  File.open(output, 'a+') { |f| registry.save(f) }
}

# restore state of motel subsystem
restore_state = proc { |input|
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)
  File.open(input, 'r') { |f| registry.restore(f) }
}

STATE_METHODS = { :save_state => save_state,
                  :restore_state => restore_state }
end

def dispatch_motel_rjr_state(dispatcher)
  m = Motel::RJR::STATE_METHODS
  dispatcher.handle "motel::save_state",    &m[:save_state]
  dispatcher.handle "motel::restore_state", &m[:restore_state]
end
