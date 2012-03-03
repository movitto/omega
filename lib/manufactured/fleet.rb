# Manufactured Fleet definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured
class Fleet
  attr_reader :id
  attr_reader :ships
  attr_reader :ship_ids

  def initialize(args = {})
    @id       = args['id']       || args[:id]
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
            rship = Manufactured::Registry.instance.find(:id => ship).first

            @ship_ids << ship
            @ships    << rship unless rship.nil?

          end
        }
      end
    }
  end

  def parent
    return solar_system
  end

  def solar_system
    return @ships.empty? ? nil : @ships.first.solar_system
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:id => id, :ship_ids => ship_ids }
     }.to_json(*a)
   end

   def self.json_create(o)
     ship = new(o['data'])
     return ship
   end

end
end
