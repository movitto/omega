# Cosmos Asteroid definition
#
# Copyright (C) 2012-2013-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'

module Cosmos
module Entities

# http://en.wikipedia.org/wiki/Asteroid
#
# Cosmos entity residing in a solar system, may be associated with
# resources through {Cosmos::ResourceSource}. Primarily interacted with
# by {Manufactured::Ship} to mine the contained resources.
class Asteroid
  include Cosmos::Entity
  include Cosmos::SystemEntity

  attr_accessor :resources

  CHILD_TYPES = []

  VALIDATE_SIZE  = proc { |s| (10...20).include?(s) }
  VALIDATE_COLOR = proc { |c| c =~ /^[a-fA-F0-9]{6}$/ }

  RAND_SIZE      = proc { rand(10) + 10               }
  RAND_COLOR     = proc { "%06x" % (rand * 0xffffff)  }

  # Cosmos::Asteroid intializer
  def initialize(args = {})
    init_entity(args)
    init_system_entity(args)

    attr_from_args args, :resources => []
  end

  # Return boolean indicating if this asteroid is valid.
  #
  # Currently tests
  # * base entity and system entity is valid
  # * location is not moving
  def valid?
    entity_valid? && system_entity_valid? &&
    @location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped) &&
    @resources.all? { |r| r.valid? }
  end

  # Return boolean indicating if this asteroid can accept the specified resource.
  #
  # TODO right now indiscremenantly accepts all valid resources, make this more selective
  def accepts_resource?(res)
    res.valid?
  end

  # Set resource locally
  def set_resource(res)
    r = @resources.find { |r| r.material_id == res.material_id }
    if r
      # simply update quantity
      if res.quantity > 0
        r.quantity = res.quantity

      # delete resource
      else
        @resources.delete(r)
      end

      return r
    end

    # add resource
    res.entity = self
    @resources << res
    return res
  end

  # Return json representation of asteroid
  def to_json(*a)
    { :json_class => self.class.name,
      :data       => {:resources => @resources }.
                             merge(entity_json).
                      merge(system_entity_json)
    }.to_json(*a)
  end

   # Create new asteroid from json representation
   def self.json_create(o)
     a = new(o['data'])
     return a
   end

end # class Asteroid
end # module Entities
end # module Cosmos
