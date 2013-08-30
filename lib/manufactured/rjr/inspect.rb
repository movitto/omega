# manufactured rjr inspect module
#
# Only included in debugging mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO
# - total # of loot instances
# - total # of commands and # of commands of each type
# - list of command ids and handle to command specified by id
# - # of entities in diffent states (docked/undocked,attacking,mining,moving)
# - # of transfers

def dispatch_manufactured_rjr_inspect(dispatcher)
  dispatcher.handle "manufactured::status" do
    # Retrieve the overall status of this node
    { :running   => registry.running?,
      :ships    => registry.ships.size,
      :stations => registry.stations.size }
  end
end
