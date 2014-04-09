# Base Registry Class
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/registry/safe_exec'
require 'omega/server/registry/has_entities'
require 'omega/server/registry/proxies_entities'
require 'omega/server/registry/has_events'
require 'omega/server/registry/runs_events'
require 'omega/server/registry/runs_commands'
require 'omega/server/registry/has_state'

module Omega
module Server
  # Provides safe centralized object store + many contextual helpers &
  # operations on entities which can be stored in it (such as events
  # and commands)
  module Registry
    include SafeExec
    include HasEntities
    include ProxiesEntities
    include HasEvents
    include RunsEvents
    include RunsCommands
    include HasState

    attr_accessor :node

    class << self
      # @!group Config options

      # Default loop poll
      attr_accessor :loop_poll

      # @!endgroup
    end


    private

    def init_registry
      init_safe_exec
      init_entities
      init_event_loops
      init_event_handlers
      init_state
    end

    public

    def to_s
      @lock.synchronize { "#{self.class}-#{@entities.size}" }
    end
  end # module Registry
end # module Server
end # module Omega
