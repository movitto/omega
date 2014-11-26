# Omega Server Command Helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
# Convencience methods which commands may include to simplify operations

module Omega
module Server
  # Mixin to be included in commands to provide various utilities
  module CommandHelpers
    # update entity in registry
    def update_registry(entity, *attrs)
      registry.update(entity, *attrs) { |e| e.respond_to?(:id) && e.id == entity.id }
    end
  
    # retrieve entity from registry
    def retrieve(entity_id)
      registry.entity { |e| e.respond_to?(:id) && e.id == entity_id }
    end
  
    # run callbacks with args on the registry entity
    def run_callbacks(entity, *args)
      registry.safe_exec { |entities|
        e = entities.find { |e| e.respond_to?(:id) && e.id == entity.id }
        e.run_callbacks *args
      }
    end
  
    # invoke a command via the node
    def invoke(*args)
      node.invoke *args
    end
  end
end # module Server
end # module Omega
