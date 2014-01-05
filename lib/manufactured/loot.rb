# Manufactured Loot definition
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/registry'
require 'cosmos/entities/solar_system'

require 'manufactured/entity'

module Manufactured

# Free floating groups of items (resources/etc) in a {Cosmos::Entities::SolarSystem}
# which {Manufactured::Ship}s can retrieve if within collection_distance
class Loot
  include Manufactured::Entity::InSystem
  include Manufactured::Entity::HasCargo

  # Unique string id of the loot
  attr_accessor :id

  # Loot initializer
  # @param [Hash] args hash of options to initialize loot with
  # @option args [String] :id,'id' id to assign to the loot
  # @option args [Motel::Location] :location,'location' location of the loot in the solar system
  def initialize(args = {})
    args[:location] =
      Motel::Location.new :coordinates => [0,0,1],
                          :orientation => [1,0,0]  unless args.has_key?(:location) ||
                                                          args.has_key?('location')

    attr_from_args args, :id                   => nil,
                         :resources            =>  [],
                         :location             => nil,
                         :system_id            => nil,
                         :solar_system         => nil,
                         :transfer_distance    =>  25,
                         :cargo_capacity       => 100

    @location.movement_strategy =
      args[:movement_strategy] if args.has_key?(:movement_strategy)
  end

  # Return boolean indicating if this loot is valid
  #
  # Tests the various attributes of the Loot, returning true
  # if everything is consistent, else false.
  #
  # Current tests
  # * id is set to a valid (non-empty) string
  # * location is set to a Motel::Location
  # * location movement strategy is stopped
  # * solar system is set to Cosmos::SolarSystem
  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&

    !@location.nil? && @location.is_a?(Motel::Location) &&
     @location.movement_strategy == Motel::MovementStrategies::Stopped.instance &&

    !@system_id.nil? &&
    (@solar_system.nil? || @solar_system.is_a?(Cosmos::Entities::SolarSystem))
  end

  # Just for compatability for now, always return true
  def alive?
    true
  end

  # Convert loot to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id,
         :location => @location,
         :system_id => @system_id,
         :resources => @resources }
    }.to_json(*a)
  end

  # Convert loot to human readable string and return it
  def to_s
    "loot-#{@id}"
  end

  # Create new loot from json representation
  def self.json_create(o)
    loot = new(o['data'])
    return loot
  end
end

end
