# Omega Client CollectsLoot Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module CollectsLoot
      # Collect specified loot
      #
      # @param [Manufactured::Loot] loot loot which to collect
      def collect_loot(loot)
        RJR::Logger.info "Entity #{id} collecting loot #{loot.id}"
        @entity = node.invoke 'manufactured::collect_loot', id, loot.id
      end
    end # module CollectsLoot
  end # module Client
end # module Omega
