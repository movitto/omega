# Omega Client DSL Cosmos Interface
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/resources'

require 'omega/constraints'

module Omega
  module Client
    module DSL
      # Create and return a new galaxy
      #
      # @param [String]   name galaxy name to lookup / assign
      # @param [Callable] bl option callback block parameter to
      #                   call w/ the newly created galaxy
      # @return [Cosmos::Entities::Galaxy] galaxy created
      def galaxy(name, &bl)
        g = Cosmos::Entities::Galaxy.new :id   => gen_uuid,
                                         :name => name
        RJR::Logger.info "Creating galaxy #{g}"
        invoke 'cosmos::create_entity', g
        dsl.run g, :galaxy => g, &bl
        g
      end

      # Return the system specified corresponding to the given id, else if not found
      # created it and return it.
      #
      # If system does not exist, and we are creating a new one,
      # \@galaxy _must_ be set. Will optionally create star if star_name is set
      #
      # @param [String] name string name of system to return or create
      # @param [String] star_name string name of star to create (only if system is being created)
      # @param [Hash] args hash of options to pass directly to system initializer
      # @param [Callable] bl option callback block parameter to call w/ the newly created system
      # @return [Cosmos::Entities::SolarSystem] system found or created
      def system(name, star_name = nil, args = {}, &bl)
        # lookup / return system
        sys =
          begin dsl.node.invoke('cosmos::get_entity', 'with_name', name)
          rescue Exception => e ; end

        if sys.nil?
          # require galaxy
          galaxy = @galaxy || args[:galaxy]
          raise ArgumentError, "galaxy nil" if galaxy.nil?

          # initialize system arguments
          sargs = args.merge({:id     => args[:id] || gen_uuid,
                              :name   => name,
                              :galaxy => galaxy})

          # create location if not specified
          unless sargs[:location]
            sys_loc = rand_invert constraint('system', 'position')
            sys_loc = Motel::Location.new(sys_loc)
            sargs[:location] = sys_loc
          end

          # initialize system
          sys  = Cosmos::Entities::SolarSystem.new(sargs)

          # create system
          RJR::Logger.info "Creating solar system #{sys} under #{galaxy}"
          invoke 'cosmos::create_entity', sys

          # optionally create star
          unless star_name.nil?
            # initialize star
            stargs = {:id   => gen_uuid,
                      :name => star_name,
                      :solar_system => sys,
                      :size => constraint('star', 'size')}
            star = Cosmos::Entities::Star.new stargs

            RJR::Logger.info "Creating star #{star} under #{sys}"
            st = invoke 'cosmos::create_entity', star
            sys.add_child st
          end
        end

        # run callback
        dsl.run sys, :solar_system => sys, &bl

        # return system
        sys
      end

      # Create a reference to a system running on a remote node
      #
      # @param [String] id string id of the system
      # @param [String] id of the remote node proxy\
      #   (proxy must be setup for this id on the server side)
      # @return [Cosmos::Entities::SolarSystem] Proxied Solar System created
      def proxied_system(system_id, proxy_id, system_args={})
        # TODO how to send request to proxied server so that
        # system properties (name, location) can just be copied ?
        sargs = system_args.merge({:id => system_id,
                                   :proxy_to => proxy_id})
        sys  = Cosmos::Entities::SolarSystem.new(sargs)

        # create system
        RJR::Logger.info "Creating proxy solar system #{sys} to #{proxy_id}"
        invoke 'cosmos::create_entity', sys
        sys
      end

      # Create new asteroid and return it.
      #
      # \@system _must_ be set to the Cosmos::Entities::SolarSystem
      #  to create the asteroid under
      #
      # @param [String] id string id of asteroid created
      # @param [Hash] args hash of options to pass directly to asteroid initializer
      # @param [Callable] bl option callback block parameter to call w/ the newly created asteroid
      # @return [Cosmos::Entities::Asteroid] asteroid created
      def asteroid(id, args={}, &bl)
        system = @solar_system || args[:solar_system]
        raise ArgumentError, "solar_system nil" if system.nil?

        aargs = args.merge({:id => id, :name => id,
                            :solar_system => system})

        unless aargs[:location]
          ast_loc = rand_invert constraint('asteroid', 'position')
          ast_loc = Motel::Location.new(ast_loc)
          aargs[:location] = ast_loc
        end

        ast = Cosmos::Entities::Asteroid.new(aargs)

        RJR::Logger.info "Creating asteroid #{ast} under #{system.name}"
        invoke 'cosmos::create_entity', ast

        dsl.run ast, :asteroid => ast, &bl
        ast
      end

      # Create a field of asteroids at the specified locations
      #
      # TODO option to set num of locations to randomly generate w/
      # parameterized bounds/location-args
      #
      # @param [Hash] args hash of options to pass to asteroid initializers
      # @option args [Array<Motel::Location>] :locations locations to assign to asteroids
      # @param [Callable] bl option callback block parameter to call w/ the newly created asteroids
      # @return [Array<Cosmos::Entities::Asteroid>] asteroids created
      def asteroid_field(args={}, &bl)
        locs = args[:locations] || []

        asts =
          locs.collect { |loc|
            id = gen_uuid
            loc.id = id
            asteroid(id, {:location => loc}.merge(args))
          }

        dsl.run asts, :asteroids => asts, &bl
        asts
      end

      # Create an asteroid belt by creating an asteroid field along an elliptical path
      #
      # @param [Hash] args hash of options used to generate elliptical path
      # @option args [Integer,Float] :p semi_latus_rectum to use when generating the elliptical path
      # @option args [Integer,Float] :e eccentricity to use when generating the elliptical path
      # @option args [Array<Array<Float>,Array<Float>] :direction major/minor direction vectors of the elliptical path axis
      # @param [Callable] bl option callback block parameter to call w/ the newly created asteroids
      # @return [Array<Cosmos::Entities::Asteroid>] asteroids created
      def asteroid_belt(args={}, &bl)
        scale = args[:scale] || 30

        p,e = args[:p],args[:e]
        p = constraint('asteroid_belt', 'p') if p.nil?
        e = constraint('asteroid_belt', 'e') if e.nil?

        direction = args[:direction]
        path = Motel.elliptical_path(p,e,direction)

        num  = path.size / scale
        locs = []
        0.upto(scale) { |i|
          p = path[num*i]
          locs << Motel::Location.new(:x => p[0], :y => p[1], :z => p[2])
        }

        asteroid_field(:locations => locs, &bl)
      end

      # Set new resource on an asteroid and return it.
      #
      # \@asteroid _must_ be set to the Cosmos::Entities::Asteroid to assoicate the
      # resource with
      #
      # @param [Hash] args hash of options to pass directly to resource initializer
      # @return [Cosmos::Resource] resource created
      def resource(args = {})
        asteroid = @asteroid || args[:asteroid]
        raise ArgumentError, "asteroid is nil" if asteroid.nil?
        rs = args[:resource] || Cosmos::Resource.new(args)
        rs.id       = gen_uuid
        rs.entity   = asteroid
        rs.quantity = args[:quantity] if args.has_key?(:quantity)
        RJR::Logger.info "Creating resource #{rs} at #{asteroid}"
        notify 'cosmos::set_resource', rs
        rs
      end

      # Create new planet and return it.
      #
      # \@solar_system _must_ be set to the Cosmos::Entities::SolarSystem
      # to create the planet under
      #
      # @param [String] name string name of planet create
      # @param [Hash] args hash of options to pass directly to planet initializer
      # @param [Callable] bl option callback block parameter to call w/ the newly created planet
      # @return [Cosmos::Entities::Planet] planet created
      def planet(name, args={}, &bl)
        # planet must be created under system
        raise ArgumentError, "solar_system is nil" if @solar_system.nil?

        # initialize planet
        pargs = args.merge({:id           => gen_uuid,
                            :name         => name,
                            :solar_system => @solar_system})
        pargs[:size] = constraint('planet', 'size')      unless pargs[:size]
        pargs[:type] = constraint('planet', 'type').to_i unless pargs[:type]
        planet = Cosmos::Entities::Planet.new(pargs)

        # create orbit if not specified
        if planet.location.ms.is_a?(Motel::MovementStrategies::Stopped)
          p = constraint('planet', 'p')
          e = constraint('planet', 'e')
          s = constraint('planet', 'speed')
          plorbit = orbit(:e => e, :p => p, :speed => s,
                          :direction => random_axis(:orthogonal_to => [0,1,0]))
          planet.location.ms = plorbit
        end

        RJR::Logger.info "Creating planet #{planet} under #{@solar_system}"
        invoke 'cosmos::create_entity', planet

        dsl.run planet, :planet => planet, &bl
        planet
      end

      # Helper to create a new movement strategy specifying an entity's orbit
      #
      # Simply wraps Elliptical movement strategy constructor with some
      # defaults for now
      # @param [Hash] args hash of options to pass directly to Elliptical initializer
      def orbit(args={})
        # TODO if direction is not specified,
        #      set orthogonal to orientation of star in parent system?
        args[:relative_to] ||= Motel::MovementStrategies::Elliptical::FOCI
        Motel::MovementStrategies::Elliptical.new args
      end

      # Helper to create a randomized orbit movement strategy
      def random_orbit(args={})
        args[:relative_to] ||= Motel::MovementStrategies::Elliptical::FOCI
        Motel::MovementStrategies::Elliptical.random args
      end
      alias :rand_orbit :random_orbit

      # Create new moon and return it.
      #
      # \@planet _must_ be set to the Cosmos::Entities::Planet to create the
      # moon under
      #
      # @param [String] name string name of moon create
      # @param [Hash] args hash of options to pass directly to moon initializer
      # @return [Cosmos::Entities::Moon] moon created
      def moon(name, args={})
        raise ArgumentError, "planet is nil" if @planet.nil?

        margs = args.merge({:id => gen_uuid,
                            :name => name,
                            :planet => @planet })
        moon = Cosmos::Entities::Moon.new(margs)

        RJR::Logger.info "Creating moon #{moon} under #{@planet}"
        notify 'cosmos::create_entity', moon
        moon
      end

      # Create a few child moons under planet
      #
      # \@planet _must_ be set to the Cosmos::Entities::Planet to create the
      # moon under
      #
      # @param [Array] names array of string names of the moons to create
      # @param [Hash] args hash of metadata options to use to create moons
      # @option args [Hash] :locations args to pass onto moon location initializers
      def moons(names, args={})
        names.collect { |name|
          moon name, :location => rand_location(args[:locations])
        }
      end

      # Create new jump gate between two systems and return it
      #
      # @param [Cosmos::Entities::SolarSystem] system source solar system containing the jump gate
      # @param [Cosmos::Entities::SolarSystem] endpoint destination solar system which the jump gate leads to
      # @param [Hash] args hash of options to pass directly to jump gate initializer
      # @return [Cosmos::Entities::JumpGate] jump gate created
      def jump_gate(system, endpoint, args = {})
        jid   = gen_uuid
        jargs = args.merge({:id   => jid,
                            :name => jid,
                            :solar_system => system,
                            :endpoint => endpoint})

        unless jargs[:location]
          jg_loc = rand_invert constraint('system_entity', 'position')
          jg_loc = Motel::Location.new(jg_loc)
          jargs[:location] = jg_loc
        end

        gate  = Cosmos::Entities::JumpGate.new(jargs)

        RJR::Logger.info "Creating gate #{gate} under #{system}"
        gate = invoke 'cosmos::create_entity', gate

        gate
      end

      # Helper to create interconnections between a series of systems
      #
      # @param [Array<Cosmos::Entities::SolarSystem>] array of systems to
      # create gates inbetween
      # @return [Cosmos::Entities::JumpGate] jump gate created
      def interconnect(*systems)
        systems = systems.first if systems.size == 1 &&
                                   systems.first.is_a?(Array)
        systems.shuffle!
        0.upto(systems.length - 2) do |i|
          # TODO how to specify location
          # TODO alternate interconn 'types' or algorithms to join
          # various systesms
          jump_gate systems[i], systems[i+1]
          jump_gate systems[i+1], systems[i]
        end
      end
    end # module DSL
  end # module Client
end # module Omega
