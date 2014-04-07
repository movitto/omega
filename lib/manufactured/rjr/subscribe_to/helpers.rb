# Manufactured RJR event-methods helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured::RJR
  # Bool indicating if user can subscribe to events on specified entity
  def subscribable_entity?(entity)
    subsystem_entity?(entity) && !entity.is_a?(Loot)
  end
end
