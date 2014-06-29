# Missions registry
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/registry'
require 'omega/server/event'
require 'omega/server/event_handler'

require 'missions/rjr/init'
require 'missions/mission'

module Missions

# Primary server side missions tracker
class Registry
  include Omega::Server::Registry

  private

  # Perform a few sanity checks on mission / update missing attributes
  def sanitize_mission(mission)
    @lock.synchronize {
      # retrieve registry mission
      rmission = @entities.find { |m|
        m.is_a?(Mission) && m.id == mission.id
      }

      # resolve creator if missing
      if !rmission.creator_id.nil? && rmission.creator.nil?
        rmission.creator =
          Missions::RJR::node.invoke('users::get_entity',
                                     'with_id', mission.creator_id)
      end

      # resolve assigned to if missing
      if !rmission.assigned_to_id.nil? && rmission.assigned_to.nil?
        rmission.assigned_to =
          Missions::RJR::node.invoke('users::get_entity',
                                     'with_id', rmission.assigned_to_id)
      end
    }
  end

  def init_callbacks
    on(:added)   { |m|
      sanitize_mission(m) if m.is_a?(Mission)
    }
  end

  # Initialize the Missions::Registry
  def initialize
    init_registry
    init_callbacks

    exclude_from_backup Omega::Server::EventHandler

    # run local events
    run { run_events }
  end

  public

  # Override registry restore operation
  def restore(io)
    super(io)

    # run through missions, restore callbacks from orig_callbacks
    self.safe_exec { |entities|
      entities.select { |e| e.is_a?(Mission) }.
               each   { |m| m.restore_callbacks }
    }
  end
end # class Registry
end # module Missions
