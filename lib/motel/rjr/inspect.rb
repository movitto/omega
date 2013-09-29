# motel rjr inspect module
#
# Only included in debugging mode
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

# TODO
# - # times specified location was updated
# - location callbacks w/ their endpoints, callback params, and # of times invoked

module Motel::RJR

# retrieve status of motel subsystem
get_status = proc {
  by_strategy =
    Motel::MovementStrategies.constants.collect { |s|
      ms  = Motel::MovementStrategies.const_get(s)
      num = registry.entities.select { |e|
              e.is_a?(Motel::Location) && e.ms.is_a?(ms)
            }.size
      [ms, num]
    }
  by_strategy = Hash[*by_strategy.flatten]

  {
    :running       => registry.running?,
    :num_locations => registry.entities.size,
    :movement_strategies => by_strategy
  }
}

INSPECT_METHODS = { :get_status => get_status }
end

def dispatch_motel_rjr_inspect(dispatcher)
  m = Motel::RJR::INSPECT_METHODS
  dispatcher.handle "motel::status", &m[:get_status]
end
