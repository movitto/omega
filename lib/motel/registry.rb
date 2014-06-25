# Motel Registry tracks all locations
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# FIXME create id if missing

require 'rjr/common'
require 'omega/server/registry'
require 'omega/server/callback'
require 'motel/mixins/registry'
require 'motel/movement_strategies/follow'
require 'motel/movement_strategies/stopped'

module Motel

# Motel::Registry is a singleton class/object which acts as the primary
# mechanism to run locations in the system.
class Registry
  include Omega::Server::Registry
  include Motel::RunsLocations
  include Motel::AdjustsHeirarchy
  include Motel::SanitizesLocations

  # validate location ids are unique before creating
  def init_validations
    validation_callback { |entities, e|
      e.is_a?(Location) && !entities.collect { |l| l.id }.include?(e.id)
    }
  end

  def init_callbacks
    # perform a few sanity checks on location / update any attributes needing it
    on(:added)   { |loc| sanitize_location(loc)}
    on(:updated) { |loc,oloc| sanitize_location(loc,oloc)}

    # setup parent when entity is added or updated
    on(:added)   { |loc| adjust_heirarchry(loc) }
    on(:updated) { |loc,oloc| adjust_heirarchry(loc,oloc) }
  end

  # run registry events on locations
  def init_events
    LOCATION_EVENTS.each { |e|
      on(e) { |loc, *args|
        @lock.synchronize{
          rloc = @entities.find { |e| e.id == loc.id }
          rloc.raise_event(e, *args)
        }
      }
    }
  end

  def initialize
    init_registry

    exclude_from_backup Omega::Server::Callback

    init_validations
    init_callbacks
    init_events

    # start location runner
    run { run_locations }
  end
end # class Registry
end # module motel
