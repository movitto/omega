# missions rjr inspect module
#
# Only included in debugging mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO
# - list of event ids and handle to event by id

module Missions::RJR

# retrieve status of the missions subsystem
get_status = proc {
  {
    :running   => registry.running?,
    :events  =>
      registry.entities { |e| e.kind_of?(Omega::Server::Event) }.size,
    :missions  =>
      registry.entities { |e| e.is_a?(Missions::Mission) }.size,
    :active    =>
      registry.entities { |e| e.is_a?(Missions::Mission) && e.active? }.size,
    :victorious    =>
      registry.entities { |e| e.is_a?(Missions::Mission) && e.victorious }.size,
    :failed    =>
      registry.entities { |e| e.is_a?(Missions::Mission) && e.failed }.size,
  }
}

INSPECT_METHODS = { :get_status => get_status }
end

def dispatch_missions_rjr_inspect(dispatcher)
  m = Missions::RJR::INSPECT_METHODS
  dispatcher.handle "missions::status", &m[:get_status]
end
