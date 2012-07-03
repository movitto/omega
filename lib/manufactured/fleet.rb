# Manufactured Fleet definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured
class Fleet
  attr_accessor :id
  attr_accessor :user_id
  attr_accessor :ships
  attr_accessor :ship_ids

  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @user_id  = args['user_id']  || args[:user_id]
    @ships    = []
    @ship_ids = []

    # TODO might not be best to access registry directly here
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

  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&
    !@user_id.nil? && @user_id.is_a?(String) && # ensure user id corresponds to actual user ?
    @ships.is_a?(Array) && @ships.select { |sh| !sh.is_a?(Manufactured::Ship) }.empty? &&
    @ship_ids.is_a?(Array) && @ship_ids.select { |si| !si.is_a?(String) }.empty? # TODO make sure ship ids & ships correspond to each other?
  end

  # TODO
  def location
    nil
  end

  def parent
    return solar_system
  end

  def solar_system
    return @ships.empty? ? nil : @ships.first.solar_system
  end

  def to_s
    "fleet-#{@id}"
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:id => id, :user_id => user_id,
          :solar_system => (solar_system.nil? ? nil : solar_system.name),
          :ship_ids => ship_ids }
     }.to_json(*a)
   end

   def self.json_create(o)
     ship = new(o['data'])
     return ship
   end

end
end
