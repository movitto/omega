# Helper module to define omega clients / robots
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega'
require 'omega/client/node'
require 'omega/resources'

module Omega
  module Client
    # Omega Client DSL, works best if you including this module in the
    # namespace you would like to use it, eg:
    #
    # @example using the dsl
    #   include Omega::Client::DSL
    #
    #   # create a new user
    #   user 'newuser', 'withpass'
    #
    #   # create a new galaxy/system/planet
    #   galaxy 'Zeus' do |g|
    #     system 'Athena', 'HR1925', :location =>
    #       Location.new(:x => 240, :y => -360, :z => 110) do |sys|
    #         planet 'Aphrodite', :movement_strategy =>
    #           orbit(:speed => 0.1, :e => 0.16, :p => 140,
    #                 :direction => random_axis(:orthogonal_to => [0,1,0]))
    #     end
    #   end
    module DSL
      # Return handle to base dsl instance, use to get/set
      # options such as node/parallel and run operations
      # such as 'join', etc
      def dsl
        @dsl_base ||= Base.new
      end

      # Generate an return a random uuid
      #
      # @see Motel.gen_uuid
      def gen_uuid
        Motel.gen_uuid
      end

      # Generate an return a new random {Cosmos::Resource}
      #
      # @see Omega::Resources.rand_resource
      def rand_resource
        Omega::Resources.random
      end

      # Generate an return a new random {Motel::Location},
      # using the specified arguments
      #
      # @see Motel::Location.random
      def rand_location(args={})
        Motel::Location.random args
      end
      alias :rand_loc :rand_location

      # Wrapper around Motel.random_axis
      def random_axis(*args)
        Motel.random_axis *args
      end
      alias :rand_axis :random_axis

      # Utility wrapper to simply return a new location
      def loc(x,y,z)
        Motel::Location.new :x => x, :y => y, :z => z
      end

      # Invoke request using the DSL node / endpoint
      def invoke(*args)
        dsl.invoke *args
      end

      # Invoke notification using the DSL node / endpoint
      def notify(*args)
        dsl.notify *args
      end

      ########################################################################

      # Log specified user into the server
      #
      # @param [String] user_id string id of the user to login
      # @param [String] password password of the user to login
      # @see Omega::Client::User.login
      def login(user_id, password)
        user = Users::User.new(:id => user_id,
                               :password => password)
        @session = invoke('users::login', user)
        dsl.node.rjr_node.message_headers['session_id'] = @session.id
      end

      # Log the user out of the server
      def logout
        invoke('users::logout', @session.id)
        @session = nil
        dsl.node.rjr_node.message_headers['session_id'] = nil
      end

      # Return user w/ the given user_id, else if it is not found create
      # it w/ the specified password and attributes
      #
      # @param [String] user_id string id to assign to the new user
      # @param [String] password password to assign to the new user
      # @param [Callable] bl option callback block parameter to call w/ the newly created user
      # @return [Users::User] user created
      def user(user_id, password = nil, args = {}, &bl)
        # lookup / return user
        begin return invoke('users::get_entity', 'with_id', user_id)
        rescue Exception => e ; end

        # create / return user
        u = Users::User.new(args.merge({:id => user_id, :password => password,
                                        :registration_code => nil}))
        invoke('users::create_user', u)
        dsl.run u, :user => u, &bl
        u
      end

      # Create a new role, or if @user is set, simply add the specified role id
      # to the user
      #
      # Operates in one of two modes depending on if \@user is set. If it is, specify
      # a string role name to this function to be added to the user indicated by
      # \@user. Else specify a Users::Role to create on the server side
      #
      # @param [Users::Role,String] nrole name of role to add to user or Users::Role to create on the server side
      def role(nrole)
        if @user
          RJR::Logger.info "Adding role #{nrole} to #{@user}"
          invoke('users::add_role', @user.id, nrole)

        else
          RJR::Logger.info "Creating role #{nrole}"
          invoke('users::create_role', nrole)
        end
      end

      ########################################################################

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
          raise ArgumentError, "galaxy nil" if @galaxy.nil?

          # initialize system
          sargs = args.merge({:id => args[:id] || gen_uuid,
                              :name => name,
                              :galaxy => @galaxy})
          sys  = Cosmos::Entities::SolarSystem.new(sargs)

          # create system
          RJR::Logger.info "Creating solar system #{sys} under #{@galaxy}"
          invoke 'cosmos::create_entity', sys

          # optionally create star
          unless star_name.nil?
            # initialize star
            stargs = {:id   => gen_uuid,
                      :name => star_name,
                      :solar_system => sys}
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
        # TODO make # of asteroids configurable
        scale = 30

        p,e = args[:p],args[:e]
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
        raise ArgumentError, "solar_system is nil" if @solar_system.nil?

        pargs = args.merge({:id => gen_uuid,
                            :name => name,
                            :solar_system => @solar_system})
        planet = Cosmos::Entities::Planet.new(pargs)

        RJR::Logger.info "Creating planet #{planet} under #{@solar_system}"
        invoke 'cosmos::create_entity', planet

        dsl.run planet, :planet => planet, &bl
        planet
      end

      # Helper to create a new movement strategy specifying a planet's orbit
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
        gate  = Cosmos::Entities::JumpGate.new(jargs)

        RJR::Logger.info "Creating gate #{gate} under #{system}"
        gate = invoke 'cosmos::create_entity', gate

        gate
      end

      ########################################################################

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

      ########################################################################

      # Schedule new periodic event w/ missions subsystem
      #
      # @param [Integer] interval which event should occur
      # @param [Missions::Event] event event which to run at specified interval
      def schedule_event(interval, event)
        evnt =
          Omega::Server::PeriodicEvent.new :id => event.id + '-scheduler',
                                           :interval => interval,
                                           :template_event => event
        RJR::Logger.info "Scheduling event #{evnt}(#{event})"
        notify 'missions::create_event', evnt
        evnt
      end

      # Create a new Missions::Mission
      #
      # @param [String] id id to assign to new mission
      # @param[Hash[ args hash of options to pass directly to mission initializer
      def mission(id, args={})
        mission = Missions::Mission.new(args.merge({:id => id}))
        RJR::Logger.info "Creating mission #{mission}"
        notify 'missions::create_mission', mission
        mission
      end

      def missions_event_handler(event, handler_method, args={})
        dsl_handler = Missions::DSL::Client::EventHandler.send(handler_method,
                                                 args.merge({:event => event}))
        handler = Missions::EventHandler.new :event_id => event,
                                             :persist  => true
        handler.exec dsl_handler
        handler
      end

      #########################################################################

      # Internal helper, used to track dsl state
      class Base
        include Omega::Client::DSL

        # override DSL::dsl, return self
        def dsl
          self
        end

        # internally managed client node
        def node
          @node ||= Client::Node.new
        end

        # get underlying rjr_node
        def rjr_node
          self.node.rjr_node
        end

        # set underlying rjr node
        def rjr_node=(val)
          self.node.rjr_node = val
        end

        # Proxy invoke to client node
        def invoke(*args)
          self.node.invoke *args
        end

        # Proxy notify to client node
        def notify(*args)
          self.node.notify *args
        end

        # Boolean indicating if dsl should be run in parallel
        attr_accessor :parallel

        # Threads being managed
        attr_accessor :workers

        # Wait until all workers complete
        def join
          @workers.each { |w| w.join }
        end

        # Set attributes and run block w/ params (via worker if parallel is true)
        #
        # TODO use thread pool for this?
        def run(params, attrs={}, &bl)
          if @parallel
            @workers <<  Thread.new(params, attrs) { |params,attrs|
              # create new base instance and run
              # block there to safely set attributes
              b = Base.new
              b.rjr_node = self.node.rjr_node
              b.run params, attrs, &bl
            }

          else
            attrs.each { |k,v| self.instance_variable_set("@#{k}".intern, v)}
            instance_exec params, &bl unless bl.nil?
            attrs.each { |k,v| self.instance_variable_set("@#{k}".intern, nil)}
          end
        end

        def initialize
          @parallel = false
          @workers  = []
        end
      end

    end
  end
end
