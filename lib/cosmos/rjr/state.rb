# cosmos::save_state, cosmos::load_state,
# rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

save_state = proc { |output|
  raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
  output_file = File.open(output, 'a+')
  Cosmos::Registry.instance.save_state(output_file)
  output_file.close
  nil
}

restore_state = proc { |input|
  raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
  input_file = File.open(input, 'r')
  Cosmos::Registry.instance.restore_state(input_file)
  input_file.close
  nil
}

def dispatch_state(dispatcher)
  dispatcher.handle "cosmos::save_state",    &save_state
  dispatcher.handle "cosmos::restore_state", &restore_state
end
