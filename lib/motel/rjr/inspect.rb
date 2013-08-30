# motel rjr inspect module
#
# Only included in debugging mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO
# - # times specified location was updated
# - location callbacks w/ their endpoints, callback params, and # of times invoked

def dispatch_motel_rjr_inspect(dispatcher)
  # retrieve status of motel subsystem
  dispatcher.handle "motel::status" do
    by_strategy =
      Motel::MovementStrategies.constants.map { |s|
        ms = Motel::MovementStrategies.const_get(s)
        [ms, registry.entities.select { |e| e.is_a?(Motel::Location) && e.ms.is_a?(ms) }.size]
      }

    {
      :running       => registry.running?,
      :num_locations => registry.entities.size,
      :movement_strategies => by_strategy
    }
  end
end
