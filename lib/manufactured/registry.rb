# Manufactured entity registry
#
# Copyright (C) 2012-2013-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/registry'
require 'omega/server/command'
require 'manufactured/ship'
require 'manufactured/station'
require 'manufactured/loot'

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

  VALID_TYPES = [Ship, Station, Loot]

  # Return array of ships tracked by registry
  def ships    ; entities.select { |e| e.is_a?(Ship)    } ; end

  # Return array of stations tracked by registry
  def stations ; entities.select { |e| e.is_a?(Station) } ; end

  # Return array of loot tracked by registry
  def loot     ; entities.select { |e| e.is_a?(Loot)    } ; end

  # Time attack thread sleeps between event cycles
  POLL_DELAY = 0.5 # TODO make configurable?

  private

  def validate_entity(entities, entity)
    # ensure entity id not taken
    entities.find { |re|
      re.class == entity.class && re.id == entity.id
    }.nil? &&

    # ensure valid entity
    entity.valid?
  end

  def check_entity(entity, old_entity=nil)
    @lock.synchronize {
      # TODO resolve system references here ?
      #rentity = @entities.find { |e| e.id == entity.id }
    }
  end

  public

  def initialize
    init_registry

    exclude_from_backup Omega::Server::Command
    exclude_from_backup Omega::Server::EventHandler

    # validate entities upon creation
    self.validation_callback { |r,e|
      # accept manufactured commands
      e.kind_of?(Omega::Server::Command) ||
      # && e.class.modulize.include?("Manufactured")

      e.kind_of?(Omega::Server::Event) ||
      e.kind_of?(Omega::Server::EventHandler) ||

       # confirm entity type & validate
      (VALID_TYPES.include?(e.class) && validate_entity(r, e))
    }

    # sanity checks on entity
    on(:added)   { |e|    check_entity(e)    if VALID_TYPES.include?(e.class) }
    on(:updated) { |e,oe| check_entity(e,oe) if VALID_TYPES.include?(e.class) }

    # sanity checks on commands
    on(:added)   { |c|    check_command(c)   if c.kind_of?(Omega::Server::Command) }

    # uniqueness checks on event handlers
    on(:added)   { |e| sanitize_event_handlers(e) if e.kind_of?(Omega::Server::EventHandler) }

    # run commands
    run { run_commands }

    # run events
    run { run_events }
  end

  def stop_commands_for(entity)
    # stop all commands related to entity
    @lock.synchronize {
      to_remove = []
      @entities.each { |reg_entity|
        if reg_entity.kind_of?(Omega::Server::Command) &&
           reg_entity.processes?(entity) # TODO flush out processes? methods
          to_remove << reg_entity
        end
      }

      @entities -= to_remove
    }
  end

end # class Registry
end # module Manufactured
