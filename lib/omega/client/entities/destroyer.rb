# Omega Client Destroyer Tracker
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'omega/client/entities/ship'

module Omega
  module Client
    # Omega client destroyer ship tracker
    class Destroyer < Ship
      include OffenseCapabilities
      include SeeksTarget

      def start_bot
        seek_and_destroy_all
      end
    end # class Destroyer
  end # module Client
end # module Omega
