# Omega Client DSL Manufactured Interface
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module DSL
      # Return station with the specified id if it exists, else
      # create new station and return it.
      #
      # Note callback will be invoked *before* station is created,
      # you may use it to set station parameters for creation
      #
      # @param [String] id string id of station create
      # @param [Hash] args hash of options to pass directly to station initializer
      # @param [Callable] bl option callback block parameter to call w/ station before it is created
      # @return [Manufactured::Station] station created
      def station(id, args={}, &bl)
        begin return invoke 'manufactured::get_entity', 'with_id', id
        rescue Exception => e ; end

        st = Manufactured::Station.new(args.merge({:id => id}))
        dsl.run st, :station => st, &bl

        RJR::Logger.info "Creating station #{st}"
        invoke 'manufactured::create_entity', st
      end

      # Return movement strategy that will orbit station around its system's star
      #
      # Currently this only supports circular orbits based on the station's
      # starting position
      def station_orbit(args={})
        raise ArgumentError, "station is nil" if @station.nil?

        speed = args[:speed] || args[:s]

        # dmaj from current station loc, dmin rand or from args
        dmaj = Motel.normalize(*@station.location.coordinates)
        dmin = Motel.normalize(*Motel.cross_product(*dmaj,
                               *Motel.normalize(rand, rand, rand)))

        Motel::MovementStrategies::Elliptical.new :e     => 0,
                                                  :p     => @station.loc.scalar,
                                                  :speed => speed,
                                                  :dmaj  => dmaj,
                                                  :dmin  => dmin
      end

      # Retrieve ship with the specified id if it exists,
      # else create new ship and return it.
      #
      # Note callback will be invoked *before* ship is created,
      # you may use it to set ship parameters for creation
      #
      # @param [String] id string id of ship create
      # @param [Hash] args hash of options to pass directly to ship initializer
      # @param [Callable] bl option callback block parameter to call w/ ship before it is created
      # @return [Manufactured::Ship] ship created
      def ship(id, args={}, &bl)
        begin return invoke 'manufactured::get_entity', 'with_id', id
        rescue Exception => e ; end

        sh = Manufactured::Ship.new(args.merge({:id => id}))
        dsl.run sh, :ship => sh, &bl

        RJR::Logger.info "Creating ship #{sh}"
        invoke 'manufactured::create_entity', sh
      end

      # Dock ship at the specified station
      def dock(ship_id, station_id)
        RJR::Logger.info "Docking #{ship_id} at #{station_id}"
        invoke 'manufactured::dock', ship_id, station_id
      end

    end # module DSL
  end # module Client
end # module Omega
