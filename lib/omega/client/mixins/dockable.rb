# Omega Client Dockable Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module Dockable
      # Dock at the specified station
      def dock_to(station)
        RJR::Logger.info "Docking #{id} at #{station.id}"
        node.invoke 'manufactured::dock', id, station.id
      end

      # Undock
      def undock
        RJR::Logger.info "Unocking #{id}"
        node.invoke 'manufactured::undock', id
      end
    end # module Dockable
  end # module Client
end # module Omega
