# Manufactured RJR event-methods helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO remove completely, use omega server dsl methods

module Manufactured::RJR
  # Bool indicating if specified entity is a subsystem entity.
  # *note* right now we're not considering Loot to be here as those
  # entities shouldn't be processed here
  def subsystem_entity?(entity)
    entity.is_a?(Ship) || entity.is_a?(Station)
  end

  # Bool indicating if specified entity is a cosmos subsystem entity
  def cosmos_entity?(entity)
    Cosmos::Entities.module_classes.any? { |cl| entity.is_a?(cl) }
  end
end
