# missions::save_state, missions::load_state rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# FIXME need to serialize mission procs on backup
# (perhaps keep client proxies passed in on mission creation & use those ?)

require 'missions/rjr/init'

module Missions::RJR
# save state of missions subsystem
save_state = proc { |output|
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)
  File.open(output, 'a+') { |f| registry.save(f) }
}

# restore state of missions subsystem
restore_state = proc { |input|
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)
  File.open(input, 'r') { |f| registry.restore(f) }
}

STATE_METHODS = { :save_state => save_state,
                  :restore_state => restore_state }

end

def dispatch_missions_rjr_state(dispatcher)
  m = Missions::RJR::STATE_METHODS
  dispatcher.handle "missions::save_state",    &m[:save_state]
  dispatcher.handle "missions::restore_state", &m[:restore_state]
end
