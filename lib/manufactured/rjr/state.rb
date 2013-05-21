# manufactured::save_state, manufactured::load_state,
# manufactured::status, rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

save_state = proc { |output|
  raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
  output_file = File.open(output, 'a+')
  Manufactured::Registry.instance.save_state(output_file)
  output_file.close
  nil
}

restore_state = proc { |input|
  raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
  input_file = File.open(input, 'r')
  Manufactured::Registry.instance.restore_state(input_file)
  input_file.close
  nil
}

manufactured_status = proc {
  # Retrieve the overall status of this node
  { :running   =>
      { :all => Manufactured::Registry.instance.running?,
        :attack => Manufactured::Registry.instance.subsys_running?(:attack),
        :mining => Manufactured::Registry.instance.subsys_running?(:mining),
        :construction => Manufactured::Registry.instance.subsys_running?(:construction),
        :shield => Manufactured::Registry.instance.subsys_running?(:shield) },
    :num_ships => Manufactured::Registry.instance.ships.size,
    :num_stations => Manufactured::Registry.instance.stations.size }
}

def dispatch_state(dispatcher)
  dispatcher.handle "manufactured::save_state",    &save_state
  dispatcher.handle "manufactured::restore_state", &restore_state
  dispatcher.handle "manufactured::status",        &manufactured_status
end
