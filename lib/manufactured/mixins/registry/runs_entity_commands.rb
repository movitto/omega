# Manufactured Registry Runs Entity Commands Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'motel/movement_strategies/stopped'

module Manufactured
module RunsEntityCommands
  def stop_commands_for(entity)
    # stop all commands related to entity
    to_remove = []
    @lock.synchronize {
      @entities.each { |reg_entity|
        if reg_entity.kind_of?(Omega::Server::Command) &&
           reg_entity.processes?(entity) # TODO flush out processes? methods
          to_remove << reg_entity
        end
      }


      @entities -= to_remove
    }

    to_remove.each { |cmd|
      cmd.registry = self
      cmd.run_hooks :stop
    }
  end
end # module RunsEntityCommands
end # module Manufactured
