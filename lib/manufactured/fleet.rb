# Manufactured Fleet definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured

# Grouping of {Manufactured::Ships} owned by a user
class Fleet
  # Unique string id of the fleet
  attr_accessor :id

  # ID of user which fleet belongs to
  attr_accessor :user_id

  # Array of ships in the fleet
  attr_accessor :ships

  # Array of ids of the ships in the fleet
  attr_accessor :ship_ids

  # Fleet initializer
  # @param [Hash] args hash of options to initialize attack command with
  # @option args [String] :id,'id' id to assign to the fleet
  # @option args [String] :user_id,'user_id' id of user that owns the fleet
  # @option args [Array<Manufactured::Ship>] :ships,'ships' array of ships to add to the fleet
  # @option args [Array<String>] :ship_ids,'ship_ds' array of ship ids to add to the fleet, the ships themselves will be looked up in the local {Manufactured::Registry}
  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @user_id  = args['user_id']  || args[:user_id]
    @ships    = []
    @ship_ids = []

    ['ships', :ships, 'ship_ids', :ship_ids].each { |si|
      if args.has_key?(si)
        ships = args[si]
        ships.each { |ship|
          if ship.is_a?(Manufactured::Ship)
            @ship_ids << ship.id
            @ships    << ship

          elsif ship.is_a?(String)
            # TODO don't like doing this here
            rship = Manufactured::Registry.instance.find(:id => ship).first

            @ship_ids << ship
            @ships    << rship unless rship.nil?

          end
        }
      end
    }
  end

  # Return boolean indicating if this fleet is valid
  #
  # Tests the various attributes of the Fleet, returning true
  # if everything is consistent, else false.
  #
  # Current tests
  # * id is set to a valid (non-empty) string
  # * user id is set to a string
  # * ships is an array of Manufacturing::Ships
  # * ship ids is an array of strings
  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&
    !@user_id.nil? && @user_id.is_a?(String) && # ensure user id corresponds to actual user ?
    @ships.is_a?(Array) && @ships.select { |sh| !sh.is_a?(Manufactured::Ship) }.empty? &&
    @ship_ids.is_a?(Array) && @ship_ids.select { |si| !si.is_a?(String) }.empty? # TODO make sure ship ids & ships correspond to each other?
  end

  # Returns the fleet location, here for manufactured interface compatabilty reasons (should not be used)
  #
  # TODO remove
  # @return nil
  def location
    nil
  end

  # Returns the fleet's parent (wrapper around solar_system), here for manufactured interface compatabilty reasons (should not be used)
  def parent
    return solar_system
  end

  # Returns the fleet's solar system, here for manufactured interface compatabilty reasons (should not be used)
  #
  # TODO remove
  # @return [Cosmos::SolarSystem] system which the first ship in the fleet is residing in,else nil
  def solar_system
    return @ships.empty? ? nil : @ships.first.solar_system
  end

  # Convert fleet to human readable string and return it
  def to_s
    "fleet-#{@id}"
  end

   # Convert fleet to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:id => id, :user_id => user_id,
          :solar_system => (solar_system.nil? ? nil : solar_system.name),
          :ship_ids => ship_ids }
     }.to_json(*a)
   end

   # Create new fleet from json representation
   def self.json_create(o)
     fleet = new(o['data'])
     return fleet
   end

end
end
