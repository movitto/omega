# Cosmos Asteroid definition
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'

module Cosmos

# http://en.wikipedia.org/wiki/Asteroid
#
# Cosmos entity residing in a solar system, may be associated with
# resources through {Cosmos::ResourceSource}. Primarily interacted with
# by {Manufactured::Ship} to mine the contained resources.
class Asteroid
  include Cosmos::Entity
  include Cosmos::SystemEntity

  CHILD_TYPES = []

  VALIDATE_SIZE  = proc { |s| (10...20).include?(s) }
  VALIDATE_COLOR = proc { |c| c =~ /^[a-fA-F0-9]{6}$/ }

  RAND_SIZE      = proc { rand(10) + 10               }
  RAND_COLOR     = proc { "%06x" % (rand * 0xffffff)  }

  # Cosmos::Asteroid intializer
  def initialize(args = {})
    init_entity(args)
    init_system_entity(args)
  end

  # Return boolean indicating if this asteroid is valid.
  #
  # Currently tests
  # * base entity and system entity is valid
  # * location is not moving
  def valid?
    entity_valid? && system_entity_valid?
    @location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped)
  end

  # Return boolean indicating if this asteroid can accept the specified resource.
  #
  # TODO right now indiscremenantly accepts all valid resources, make this more selective
  def accepts_resource?(res)
    res.valid?
  end

  # Return json representation of asteroid
  def to_json(*a)
    { :json_class => self.class.name,
      :data       => entity_json.merge(system_entity_json)
    }.to_json(*a)
  end
end # class Asteroid
end # module Cosmos
