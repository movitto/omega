# motel rjr inspect module
#
# Only included in debugging mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO
# - locations w/ movement strategy of each type
# - # times specified location was updated
# - location callbacks w/ their endpoints, callback params, and # of times invoked

def dispatch_motel_rjr_inspect(dispatcher)
  # retrieve status of motel subsystem
  dispatcher.handle "motel::status" do
    {
      :running       => registry.running?,
      :num_locations => registry.entities.size
    }
  end
end
