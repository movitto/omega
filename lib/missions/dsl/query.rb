# Mission Querying DSL
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'missions/dsl/helpers'

module Missions
module DSL

# Mission Queries
module Query
  include Helpers

  # Return bool indicating if the ships hp == 0 (eg ship is destroyed)
  def self.check_entity_hp(id)
    proc { |mission|
      # check if entity is destroyed
      entity = mission.mission_data[id]
      entity = node.invoke('manufactured::get_entity', entity.id)
      entity.nil? || entity.hp == 0
    }
  end

  # Return bool indicating if user has acquired target mining quantity
  def self.check_mining_quantity
    proc { |mission|
      q = mission.mission_data['resources'][mission.mission_data['target']]
      mission.mission_data['quantity'] <= q
    }
  end

  # Return bool indicating if user has transfered the target resource
  def self.check_transfer
    proc { |mission|
      mission.mission_data['last_transfer'] &&

      mission.mission_data['check_transfer']['dst'].id ==
      mission.mission_data['last_transfer']['dst'].id  &&

      mission.mission_data['check_transfer']['rs'] ==
      mission.mission_data['last_transfer']['rs']  &&

      mission.mission_data['check_transfer']['q'] >=
      mission.mission_data['last_transfer']['q']
    }
  end

  # Return boolean indicating if user has collected the target loot
  def self.check_loot
    proc { |mission|
      !mission.mission_data['loot'].nil?
      !mission.mission_data['loot'].find { |rs|
        rs.material_id == mission.mission_data['check_loot']['res'] &&
        rs.quantity    >= mission.mission_data['check_loot']['q']
      }.nil?
    }
  end

  # Return ships the user owned that matches the speicifed properties filter
  def self.user_ships(filter={})
    proc { |mission|
      node.invoke('manufactured::get_entity',
                  'of_type', 'Manufactured::Ship',
                  'owned_by', mission.assigned_to_id).
        select { |s| filter.keys.all? { |k| s.send(k).to_s == filter[k].to_s }}
    }
  end

  # Return first ship returned by user_ships
  def self.user_ship(filter={})
    proc { |mission|
      user_ships(filter).call(mission).first
    }
  end

  # Return bool indicating if all user entities have been destroyed
  def self.entities_destroyed(filter={})
    proc { |mission|
      node.invoke('manufactured::get_entity', *filter.to_a.flatten)
          .none? { |e| e.alive? }
    }
  end

end # module Query
end # module DSL
end # module Missons

