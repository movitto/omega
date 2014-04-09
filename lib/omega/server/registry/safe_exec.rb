# Base Registry SafeExec Mixin
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
module Server
module Registry
  module SafeExec
    def init_safe_exec
      @lock ||= Mutex.new
    end

    # Safely execute a block of code in the context of the local registry.
    #
    # Pasess the raw entities array to block for unrestricted querying/manipulation
    # (be careful!)
    def safe_exec
      init_registry
      @lock.synchronize {
        yield @entities
      }
    end
  end # module SafeExec
end # module Registry
end # module Server
end # module Omega
