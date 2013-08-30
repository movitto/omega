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

def dispatch_manufactured_rjr_inspect(dispatcher)
  dispatcher.handle "manufactured::command" do |command_id|
    registry.entity { |e| e.kind_of?(Omega::Server::Command) &&
                          e.id == command_id }
  end

  dispatcher.handle "manufactured::status" do
    commands = {}
    registry.entities.select { |e| e.kind_of?(Omega::Server::Command) }.
             each { |c|
               commands[c.class.name] ||= []
               commands[c.class.name] << c.to_s
             }

    # Retrieve the overall status of this node
    { :running   => registry.running?,
      :ships    => registry.ships.size,
      :stations => registry.stations.size,
      :commands => commands }
  end
end
