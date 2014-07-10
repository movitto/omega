# Motel Registry tracks all locations
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# FIXME create id if missing

require 'omega/server/registry'
require 'omega/server/callback'
require 'motel/mixins/registry'

require 'motel/movement_strategies'

module Motel

# Motel::Registry is a singleton class/object which acts as the primary
# mechanism to run locations in the system.
class Registry
  include Omega::Server::Registry
  include Motel::RunsLocations
  include Motel::AdjustsHeirarchy
  include Motel::SanitizesLocations

  private

  # Validate location ids are unique before creating
  def init_validations
    validation_callback { |entities, check|
      entity_ids = entities.collect { |loc| loc.id }
      check.is_a?(Location) && !entity_ids.include?(check.id)
    }
  end

  # Wire up event callbacks
  def init_callbacks
    on(:added)   { |loc|
      @lock.synchronize {
        rloc = @entities.find { |entity| entity.id == loc.id }
        sanitize_location(rloc)
        adjust_heirarchry(rloc)
      }
    }

    on(:updated) { |loc, oloc|
      @lock.synchronize {
        rloc = @entities.find { |entity| entity.id == loc.id }
        sanitize_location(rloc, oloc)
        adjust_heirarchry(rloc, oloc)
      }
    }
  end

  def initialize
    init_registry
    init_validations
    init_callbacks

    exclude_from_backup Omega::Server::Callback

    run { run_locations }
  end
end # class Registry
end # module motel
