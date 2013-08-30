# manufactured::save_state, manufactured::load_state,
# manufactured::status, rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'

module Manufactured::RJR

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

STATE_METHODS = { :save_state    => save_state,
                  :restore_state => restore_state }
end

def dispatch_manufactured_rjr_state(dispatcher)
  m = Manufactured::RJR::STATE_METHODS
  dispatcher.handle "manufactured::save_state",    &m[:save_state]
  dispatcher.handle "manufactured::restore_state", &m[:restore_state]
end
