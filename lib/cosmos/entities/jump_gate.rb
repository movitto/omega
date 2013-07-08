# Cosmos JumpGate definition
#
# Copyright (C) 2012-2013-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'

module Cosmos
module Entities

# Represents a link between two systems.
#
# Reside in a {Cosmos::SolarSystem} (the jump_gate's parent) at a
# specified location and references another system (the endpoint). 
# Primarily interacted with by {Manufactured::Ship} instances who
# require jump gates to travel inbetween systems
class JumpGate
  include Cosmos::Entity
  include Cosmos::SystemEntity

  CHILD_TYPES = []

  VALIDATE_SIZE  = proc { |s| true }
  VALIDATE_COLOR = proc { |c| true }

  RAND_SIZE      = proc { 0        }
  RAND_COLOR     = proc { ''       }

  # ID of system which jump gate connects to
  attr_accessor :endpoint_id

  # {Cosmos::SolarSystem} system which jump gates connects to
  attr_reader :endpoint

  # Set endpoint system and id
  def endpoint=(val)
    @endpoint = val
    @endpoint_id = val.id unless val.nil?
  end

  # Max distance in any direction around
  #   gate which entities can trigger it
  attr_accessor   :trigger_distance

  # Cosmos::JumpGate intializer
  # @param [Hash] args hash of options to initialize jump gate with
  # @option args [Cosmos::SolarSystem,String] :endpoint,'endpoint'
  #   solar_system which jump gate connects to or its name to be looked up
  #   in the {Cosmos::Registry}
  def initialize(args = {})
    init_entity(args)
    init_system_entity(args)
    attr_from_args args, :endpoint_id      => nil,
                         :endpoint         => nil,
                         :trigger_distance => 100  # TODO make default configurable
  end

  # Return boolean indicating if this jump gate is valid.
  #
  # Currently tests
  # * base entity and system entity is valid
  # * location is not moving
  # * endpoint is set to a valid Cosmos::SolarSystem
  # * trigger distance is > 0
  def valid?
    entity_valid? && system_entity_valid? &&
    @location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped) &&
    !@endpoint_id.nil? &&
    (@endpoint.nil? || (@endpoint.is_a?(SolarSystem) && @endpoint.valid?)) &&
    # \@solar_system.name != @endpoint.name &&
    @trigger_distance.numeric? && @trigger_distance > 0
  end

  # Convert jump gate to human readable string and return it
  def to_s
    "jump_gate-#{parent_id}->#{endpoint_id}"
  end

  # Return json representation of jump gate
  def to_json(*a)
    { :json_class => self.class.name,
      :data       =>
        {:trigger_distance => @trigger_distance,
         :endpoint_id      => @endpoint_id
        }.merge(entity_json).merge(system_entity_json)
    }.to_json(*a)
  end

   # Create new jump_gate from json representation
   def self.json_create(o)
     j = new(o['data'])
     return j
   end

end # class JumpGate
end # module Entities
end # module Cosmos
