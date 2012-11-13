## How to write an Omega client

In the examples/integration directory you will find an implementation
of a few example binaries using the Omega client interfaces to setup
a simple universe containing user ships and stations. Those then can
be run via algorithms defined in client utilities known as a 'bots'.

Each utility may run directly from the command line:

* *universe.rb*: create the complete universe data set, accepts no arguments
* *environment.rb*: create a minimal universe data set, accepts no arguments
* *users.rb*: sets up a new user with their own alliance, a station, and three ships, a
  miner, a frigate, and a corvette. For the arguments, specify the username,
  password, starting system, and optionally any number or roles ('regular_user'
  at a minimum to be able to run the bot)
* *bot.rb*: the first bot using the Omega dsl, currently deprecated in favour of bot2.rb
  which uses the Omega client registry
* *bot2.rb*: runs the ships and stations algorthims for the specified user, using mining
  ships to seek out, move to, and mine resources; corvettes to protect miners,
  and attack enemys; frigates to shuttle resources to stations; and stations
  to construct more ships and stations. For the command line arguments,
  specify the username and password of the user whose bot you want to run
* *runner.sh*: simple wrapper script that sets up the universe, a few users, and launches
  bots to control them, accepts no arguments
* *monitor.rb*: uses the Omega admin account to monitor all server side entities, displaying
  live statistics via ncurses. Accepts no arguments


## Setting Up The Universe


unvierse.rb and environment.rb use the Omega dsl defined in {file:lib/omega/client.rb}
to setup heirarchies of galaxies, systems, planets, etc in a clean manner.

Invoke these utilities by running the following from the top level project directory:

    $ export RUBY_LIB='lib'
    $ ./examples/integeration/universe.rb
    $ ./examples/integeration/environment.rb

To define your own universe create a ruby script with the following contents:

    require 'rubygems'
    require 'omega'
    
    include Omega::DSL
    include Motel
    include Motel::MovementStrategies
    
    # login as the admin user (need sufficient permissions to create cosmos entities)
    login 'admin',  :password => 'nimda'
    
    # retrieves the specified galaxy, creating it if it doesn't exist
    # specify the galaxy name
    galaxy 'AF1422' do |g|
    
      # retrieves the specified system, creating it if it doesn't exist
      # specify the system name (if creating specify star name and location)
      system 'BB1122', 'BB1122', :location => Location.new(:x => 240, :y => -360, :z => 110) do |sys|
    
        # retrieves the specified planet, creating it if it doesn't exist
        # specify the planet name (and orbital path if creating)
        planet 'A4FF33',
               :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                    :eccentricity => 0.6, :semi_latus_rectum => 150,
                                                    :direction => Motel.random_axis) do |pl|
    
          # retrieves the specified moon, creating it if it doesn't exist
          # specify the moon name (and location if creating)
          moon 'EEE000',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
          
          # ... additional moons around A4FF33
        end
    
        # ... additional planets in BB1122
      end
    
      system '8744AA', '8744BB', :location => Location.new(:x => -90, :y => -22, :z => 523)
    
      # creates a jump gate between the specified systems
      # specify the source system, destination system, and location in systems
      jump_gate system('BB1122'), system('8744AA'), :location => Location.new(:x => -150, :y => -150, :z => -150)
    
      # ... additional systems and jump gates in AF1422
    end
    
    # ... additional galaxies in the universe

## Creating Users

users.rb uses the Omega dsl to create a user and an alliance which that user belongs to.

Furthermore a manufacturing station is created in the specified system along with
three ships, a miner, a frigate, and a corvette all belonging to that user.

To run the users.rb utility, simply invoke it from the command line, specifying the
username and password of the user to create and the starting system to create their
station and ships in:

    # from the top level project directory
    $ export RUBY_LIB='lib'
    $ ./examples/integeration/users.rb jsmith secret_pass BB1122 regular_user <optional-additional-role-names>

The bot2.rb utility looks for stations and ships matching the id's specified in
users.rb and invokes operations against the Omega server to manipulate them based
on their current state. (see bot2 below)

To define a user owning manufacturing entities in you own custom manner, create
a ruby script with the following contents:

    require 'rubygems'
    require 'omega'
    
    include Omega::DSL
    include Motel
    include Motel::MovementStrategies
    
    # login as the admin user (need sufficient permissions to create users)
    login 'admin',  :password => 'nimda'
    
    # retrieves the specified user, creating it if not found
    u = user 'jsmith', :password => 'secret_pass' do
          # assigns the specified role to user
          role :regular_user
        end
    
    # retrieve / create alliances
    alliance "jsmith-alliance", :members => [u]
    
    # retrieve starting system
    starting_system = system('8744AA')
    
    # retrieve / create station
    station("jsmith-manufacturing-station1") do |station|
      station.type     = :manufacturing
      station.user_id  = 'jsmith'
      station.solar_system = starting_system
      station.location = Location.new(:x => 100,  :y=> 100,  :z => 100)
    end
    
    # retrieve / create ship
    ship("jsmith-mining-ship1") do |ship|
      ship.type     = :mining
      ship.user_id  = 'jsmith'
      ship.solar_system = starting_system
      #ship.location = Location.new(:x => 30, :y=> -20, :z => 20)
      ship.location = Location.new(:x => 20, :y=> 40, :z => 40)
    end


## Running Bots

bot2.rb uses the Omega client registry defined in {file:lib/omega/registry.rb}
to monitor and track server side entities from all the Omega subsystems.

It begins by loading the ships and stations belonging to the specified user
and searching for ones with id's matching specified regex's. It then associates
each one of these with a tracker object that is used from there on out to query
and manipulate the entity.

The bot looks for stations and ships with the following ids. As new entities are
created during the course of the bots run cycle, they will be automatically loaded.

* [USER_NAME]-manufacturing-station.*
* [USER_NAME]-frigate-ship.*
* [USER_NAME]-mining-ship.*
* [USER_NAME]-corvette-ship.*

You may invoke the bot by simply passing it the username and password on the
command line:

    # from the top level project directory
    $ export RUBY_LIB='lib'
    $ ./examples/integration/bot2.rb jsmith secret_pass


To use the Omega registry interface, define an 'output' class with a 'registry'
accessor and a 'refresh' method that takes an optional entity. Pass this into
a new instance of Omega::MonitoredRegistry along with the RJR node which you
wish to use to communicate with the server. Finally invoke start to begin
asyncronously monitoring server side entities (and optionally 'join' to block
until completion)

The output object's registry attribute will be set to the instantiated registry
and refresh will be periodically called after. If no arguments are passed to refresh
the registry just performed a periodic polling operation which all entities are updated
with their server side states. If an entity is passed to the refresh method, the registry
was sent an entity update via a callback mechanism (for example on a location's movement)
and updates to only that entity needs to be handled on the client side.

Furthmore the registry module provides client side trackers for cosmos entities, users,
and ships/stations. Whenever a server-side update occurs to one of these entities,
a callback is invoked on the registry, which then updates the local object to reflect
the server state. This is before the output's refresh method is invoked, so by that
point the developer can be assured client side entities reflect the server side states.

The definition and use of an example output class would look like:

    require 'rubygems'
    require 'omega'
    
    class BotOutput
      attr_accessor :registry
    
      def refresh(invalidated = nil)
        # access entities via @registry.galaxies, @registry.users, @registry.users[0].ships, etc...
    
        if invalidated == nil
          # all registry entries were updated, handle appropriately
        else
          # the invalidated entity was update (may be a user, ship, etc)
          # handle appropriately
        end
    
      end
    end
    
    node = RJR::AMQPNode.new :broker => 'localhost', :node_id => bot_id
    
    user = Users::User.new :id => 'jsmith', :password => 'secret_pass'
    session = node.invoke_request 'omega-queue', 'users::login', user
    node.message_headers['session_id'] = session.id
    
    output = BotOutput.new
    Omega::MonitoredRegistry.new(node, output).start.join


This will continuously monitor the server, updating the registered output
object periodically and on server events. The output instance can then use
the node (accessible via registry.node) to issue additional requests to
manipulate the entries on the server side.

## Final thoughts

Finally it must be mentioned that since the Omega server implements a json-rpc
interface over a variety of protocols, the end user is more than welcome to write
clients in any language and environment of their choosing.

The Omega project ships a javascript client based on the websockets and http interface
to easily invoke Omega functionality via a web browser.

Any language that has a json-rpc library and supports tcp or http communication should
be able to easily issue and receive requests from an Omega server.

See the RJR project and the JSON-RPC protocol in general for more info
