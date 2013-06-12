# Missions registry
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/registry'
require 'missions/rjr/init'

module Missions

# Primary server side missions tracker
class Registry
  include Omega::Server::Registry

  private

  def check_mission(mission)
    @lock.synchronize {
      # retrieve registry mission
      rmission = @entities.find { |m|
        m.is_a?(Mission) && m.id == mission.id
      }

      # resolve creator if missing
      if !rmission.creator_id.nil? && rmission.creator.nil?
        mission.creator =
          Missions::RJR::node.invoke('users::get_entity',
                                     'with_id', mission.creator_id)
      end

      # resolve assigned to if missing
      if !rmission.assigned_to_id.nil? && rmission.assigned_to.nil?
        mission.assigned_to =
          Missions::RJR::node.invoke('users::get_entity',
                                     'with_id', rmission.assigned_to_id)
      end
    }
  end

  public

  # Initialize the Missions::Registry
  def initialize
    # perform a few sanity checks on mission / update missing attributes
    on(:added)   { |m|    check_mission(m)    if m.is_a?(Mission) }

    # run local events
    run { run_events }
  end

end # class Registry
end # module Missions
