## The Omega Simulation Framework

Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>

Omega is made available under the GNU AFFERO GENERAL PUBLIC LICENSE
as published by the Free Software Foundation, either version 3
of the License, or (at your option) any later version.

## Intro
The Omega Project aims to develop a universal simulator accessible by registered
users over the json-rpc protocol. This allows the most users and developers to access
and control entities and subsystems via any programming language and transport protocol.

Omega consists of several subprojects:

* **Motel** - Movable Objects Tracking Encompassing Locations - A framework to track
locations in 3d cartesian space. Locations are associated with movement strategies
on the server side whose job is to periodically update the location's coordinates
(eg along linear, elliptical paths, following another location, etc)

* **Users** - User registrations, sessions, permissions, groups, etc

* **Cosmos** - Permits clients to retreive and track heirarchies of cosmos entities,
galaxies, solar systems, stars, planets, moons, asteroids, etc. Each cosmos entity
is associated with a location tracked by Motel.

* **Manufactured** - Permits clients to construct and manipulate player controlled and
constructed entities, ships, stations, etc. Similar to the cosmos subsystem, each
manufactured entity is associated with a location managed by Motel.

* **Omega** - Besides providing convenience utilities to bind the various subsystems
together, the Omega module also provides simple mechanisms which to easily invoke
functionality via a remote client. This includes a simple dsl which can be used to
write setup scripts and a synchronized / thread-safe client-side entity-tracker.


## Running the Server

First install Omega's dependencies:

    $ gem install rjr

Checkout the project via git

    $ git clone http://github.com/movitto/omega.git

Run the server:

    $ cd omega/
    $ export RUBY_LIB='lib'
    $ ./bin/omega-server


That is it! All the necessary server logic will be invoked to
setup the remote method handlers and begin listening for requests
over a variety of protocols! It is then up to clients to invoke
the rpc methods to create and manipulate server side entities.
(see 'Invoking' below)

You may configure the application in various ways by editing
omega.yml which is loaded from the following locations
(in order, config options from later files will override former ones)

* /etc/omega.yml
* ~/.omega.yml
* ./omega.yml


## Invoking
{http://rubydoc.info/github/movitto/rjr/frames RJR}
allows Omega to serve JSON-RPC requests over many protocols.
Currently the default server listens for requests via TCP, HTTP,
Websockets, and AMQP. All a client has to do is send a string
containing a json request to the server via any of these protocols.

    # A simplified example (authentication has been disabled)

    $ curl -X POST http://localhost:8888 -d \
       '{"jsonrpc":"2.0", "method":"cosmos::get_entities",
         "params":["of_type", "solarsystem"], "id":"123"}'

    => {"jsonrpc":"2.0","id":"123","result":[{"json_class":"Cosmos::SolarSystem","data":{"name":"..."}}]}
   


RJR provides mechanisms to invoke client requests very simply via Ruby:

    # A more complete example, involving authentication
    login_user = Users::User.new :id => 'me', :password => 'secret'
    node = RJR::AMQPNode.new :node_id => 'client', :broker   => 'localhost'

    # omega-queue is the name of the server side amqp queue
    session = node.invoke_request('omega-queue', 'users::login', login_user)
    node.headers['session_id'] = session.id

    node.invoke_request('omega-queue', 'cosmos::get_entities', 'of_type', 'solarsystem')
    # => [#<Cosmos::SolarSystem:0x00AABB...>,...]


Once authenticated, the client may invoke a variety of requests to create,
retrieve, and update server side entities, depending on roles they have
been assigned and their corresponding privileges / permissions. Some methods
have additional restrictions to limit user access, see the api documentation
in the {file:API.md} file and source code (see 'generating documentation' below) for more info

## Running the clients

Omega provides a few client helper utilities in the bin/util directory.

These are meant to assist in the creation of users and the entities they own, and
to retrieve cosmos and other entities. 

To invoke, simply run the scripts right from the command line, specifying
'-h' or '--help' for extended usage.

Omega also provides a few example clients in the 'examples' directory utilizing
the various client mechanisms to setup sample data and run clients implementing
different strategies / algorithms. See the {file:examples/integration/CLIENT_HOWTO.md} for more info

## Using

Generate documentation via

  rake yard

To run test suite:

  rake spec

## Authors
 Mohammed Morsi <mo@morsi.org>
