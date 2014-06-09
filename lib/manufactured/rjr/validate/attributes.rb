# manufactured entity validation helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'users/attributes/own'

module Manufactured::RJR
  # Helper to validate use attributes upon entity creation
  def validate_user_attributes(entities, entity)
    # only applies to ships / stations
    # TODO skip this requirement if entity belongs to a npc user
    if entity.is_a?(Ship) || entity.is_a?(Station)
      # retrieve alive entities belonging to user
      n = entities.count { |e| (e.is_a?(Ship) || e.is_a?(Station)) &&
                                e.user_id == entity.user_id        &&
                              (!e.is_a?(Ship) || e.alive?)            }
  
      require_attribute :node => Manufactured::RJR.node,
        :user_id => entity.user_id,
        :attribute_id => Users::Attributes::EntityManagementLevel.id,
        :level => n+1
  
      # TODO also ensure user has attribute enabling them to
      # create entity of the specified type
    end
  end
end # module Manufactured::RJR
