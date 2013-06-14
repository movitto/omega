# cosmos::save_state, cosmos::load_state,
# rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/rjr/init'

module Cosmos::RJR
# save state of cosmos subsystem
save_state = proc { |output|
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)
  File.open(output, 'a+') { |f| registry.save(f) }
}

# restore state of cosmos subsystem
restore_state = proc { |input|
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)
  File.open(input, 'r') { |f| registry.restore(f) }
}

STATE_METHODS = { :save_state => save_state,
                  :restore_state => restore_state }
end

def dispatch_cosmos_rjr_state(dispatcher)
  m = Cosmos::RJR::STATE_METHODS
  dispatcher.handle "cosmos::save_state",    &m[:save_state]
  dispatcher.handle "cosmos::restore_state", &m[:restore_state]
end
