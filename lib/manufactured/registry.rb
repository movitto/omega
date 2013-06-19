# Manufactured entity registry
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
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

  def check_entity(entity, old_entity=nil)
    @lock.synchronize {
      # TODO resolve system references here
      rentity = @entities.find { |e| e.id == entity.id }
    }
  end

  public

  def initialize
    init_registry

    # validate entities upon creation
    self.validation = proc { |r,e|
      # accept manufactured commands
      # TODO validate command id is unique
      e.kind_of?(Omega::Server::Command) || # && e.class.modulize.include?("Manufactured")

       # confirm entity type
      (VALID_TYPES.include?(e.class) &&

       # ensure entity id not take
       r.find { |re| re.id == e.id }.nil? &&

       # ensure valid entity
       e.valid?)
    }

    # sanity checks on entity
    on(:added)   { |e|    check_entity(e) if VALID_TYPES.include?(e.class) }
    on(:updated) { |e,oe| check_entity(e) if VALID_TYPES.include?(e.class) }

    # run commands
    run { run_commands }
  end

end # class Registry
end # module Manufactured
