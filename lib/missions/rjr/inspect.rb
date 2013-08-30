# missions rjr inspect module
#
# Only included in debugging mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO
# - list of event ids and handle to event by id

def dispatch_missions_rjr_inspect(dispatcher)
  dispatcher.handle "missions::status" do
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
  end
end
