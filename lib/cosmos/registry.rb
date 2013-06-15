# Cosmos entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/registry'
require 'cosmos/entities/galaxy'
require 'cosmos/entities/solar_system'
require 'cosmos/entities/star'
require 'cosmos/entities/planet'
require 'cosmos/entities/jump_gate'
require 'cosmos/entities/asteroid'
require 'cosmos/entities/moon'

module Cosmos

# Primary server side entity tracker for Cosmos module.
#
# Provides a thread safe registry through which cosmos
# entity heirarchies and resources can be accessed.
class Registry
  include Omega::Server::Registry
  include Cosmos::Entities

  VALID_TYPES = 
    [Galaxy, SolarSystem, JumpGate, Star, Planet, Moon, Asteroid]

  private
  
  def check_entity(entity)
    @lock.synchronize{
      re = @entities.find { |e| e.id == entity.id }

      if re.parent.nil? && !re.parent_id.nil?
        p = @entities.find { |e| e.id == re.parent_id }
        re.parent = p
        p.add_child re
      end
    }
  end

  def check_jump_gate(jump_gate)
    @lock.synchronize{
      re = @entities.find { |e| e.id == jump_gate.id }

      if re.endpoint.nil? && !re.endpoint_id.nil?
        s = @entities.find { |e| e.is_a?(SolarSystem) && e.id == re.endpoint }
        re.endpoint = s
      end
    }
  end

  public

  # Cosmos::Registry intitializer
  def initialize
    init_registry

    # validate entities, ensure
    self.validation = proc { |r,e|
      # they are of valid type and valid
      VALID_TYPES.include?(e.class) && e.valid? &&

      # they have unique ids
      r.find { |re| re.id == e.id }.nil? &&

      # rhey have unqiue names
      r.find { |re| re.name == e.name }.nil? &&

      # if required, parent_id is set and is valid reference
      (e.class::PARENT_TYPE == 'NilClass' ||
       (!e.parent_id.nil? &&
        !r.find { |re| re.id == e.parent_id }.nil?) ) &&

      # jump gate endpoint is valid reference
      (!e.is_a?(JumpGate) || !r.find { |re| re.id == e.endpoint_id }.nil?)
    }

    # perform sanity checks on entity / adjust attributes
    on(:added) { |e| check_entity   e                       }

    # perform additonal checks on jump gate
    on(:added) { |e| check_jump_gate e if e.is_a?(JumpGate) }

# TODO when setting rs: if quantity == 0 delete
# old resource source, or create new source or
# add quantity to old

  end
end # class Registry
end # module Cosmos
