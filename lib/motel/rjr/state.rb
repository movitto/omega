# motel::save_state, motel::load_state,
# motel::status rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

save_state = proc { |output|
  raise Omega::PermissionError,
               "invalid client" unless @rjr_node_type ==
                                       RJR::LocalNode::RJR_NODE_TYPE
  output_file = File.open(output, 'a+')
  Motel::Runner.instance.save_state(output_file)
  output_file.close
  nil
}

restore_state = proc { |input|
  raise Omega::PermissionError,
               "invalid client" unless @rjr_node_type ==
                                       RJR::LocalNode::RJR_NODE_TYPE
  input_file = File.open(input, 'r')
  Motel::Runner.instance.restore_state(input_file)
  input_file.close
  nil
}

motel_status = proc { ||
  # Retrieve the overall status of this node
  {
    :running       => Motel::Runner.instance.running?,
    :num_locations => Motel::Runner.instance.locations.size,
    :errors        => Motel::Runner.instance.errors }
  }
}

def dispatch_state(dispatcher)
  dispatcher.handle "motel::save_state",    &save_state
  dispatcher.handle "motel::restore_state", &restore_state
  dispatcher.handle "motel::status",        &motel_status
end
