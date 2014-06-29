# Manufactured entity registry
#
# Copyright (C) 2012-2013-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/registry'
require 'omega/server/command'
require 'manufactured/ship'
require 'manufactured/station'
require 'manufactured/loot'

require 'manufactured/mixins/registry'

module Manufactured

# Primary server side entity tracker for Manufactured module.
#
# Provides a thread safe registry through which manufactured
# entity heirarchies and resources can be accessed.
#
# Singleton class, access via Manufactured::Registry.instance.
class Registry
  include Omega::Server::Registry
  include Manufactured
  include HasEntities
  include RunsEntityCommands

  VALID_TYPES = [Ship, Station, Loot]

  # Time attack thread sleeps between event cycles
  POLL_DELAY = 0.5 # TODO make configurable?

  private

  def init_validations
    validation_callback { |entities, check|
      check.kind_of?(Omega::Server::Command) ||
      # && check.class.modulize.include?("Manufactured")

      check.kind_of?(Omega::Server::Event) ||
      check.kind_of?(Omega::Server::EventHandler) ||

      (VALID_TYPES.include?(check.class) && validate_entity(entities, check))
    }
  end

  def validate_entity(entities, entity)
    # ensure entity id not taken
    has_entity = entities.any? { |re| re.class == entity.class &&
                                      re.id    == entity.id       }
    # ensure valid entity
    !has_entity && entity.valid?
  end

  def init_callbacks
    on(:added)   { |entity|
      # sanity checks on commands
      if entity.kind_of?(Omega::Server::Command)
        check_command(entity)

      # uniqueness checks on event handlers
      elsif entity.kind_of?(Omega::Server::EventHandler)
        sanitize_event_handlers(entity)

      end
    }
  end

  def initialize
    init_registry
    init_validations
    init_callbacks

    exclude_from_backup Omega::Server::Command
    exclude_from_backup Omega::Server::EventHandler

    run { run_commands }
    run { run_events }
  end
end # class Registry
end # module Manufactured
