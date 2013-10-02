# manufactured rjr inspect module
#
# Only included in debugging mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO
# - total # of loot instances
# - # of entities in diffent states (docked/undocked,attacking,mining,moving)
# - # of transfers

module Manufactured::RJR

# retrieve a manufactured cmd by id
get_cmd = proc { |cmd_id|
  registry.entity { |e| e.kind_of?(Omega::Server::Command) && e.id == cmd_id }
}

# retrieve status of the manufactured subsystem
get_status = proc {
  commands = {}
  registry.entities.select { |e| e.kind_of?(Omega::Server::Command) }.
           each { |c|
             commands[c.class.name] ||= []
             commands[c.class.name] << c.to_s
           }

  # Retrieve the overall status of this node
  { :running   => registry.running?,
    :ships     => registry.ships.size,
    :stations  => registry.stations.size,
    :commands  => commands }
}

INSPECT_METHODS = { :get_cmd => get_cmd,
                    :get_status => get_status }
end

def dispatch_manufactured_rjr_inspect(dispatcher)
  m = Manufactured::RJR::INSPECT_METHODS

  dispatcher.handle "manufactured::command", &m[:get_cmd]
  dispatcher.handle "manufactured::status", &m[:get_status]
end
