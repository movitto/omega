# Base Registry ProxiesEntities Mixin
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/proxy'
require 'rjr/util/json_parser'

module Omega
module Server
module Registry
  module ProxiesEntities
    # Return proxy objects for entities specified by selector
    # which may be used to update entities safely w/out going
    # directly through the registry
    #
    # TODO invalidate proxies if corresponding entities are deleted ?
    def proxies_for(&selector)
      init_registry
      @lock.synchronize {
        @entities.select(&selector).
                  collect { |e| ProxyEntity.new(e, self) }
      }
    end

    # Return a single proxy object for the first matched entity,
    # nil if not found
    def proxy_for(&selector)
      proxies_for(&selector).first
    end
  end # module ProxiesEntities
end # module Registry
end # module Server
end # module Omega
