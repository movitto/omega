## The Omega Simulation Framework

Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>

Omega is made available under the GNU AFFERO GENERAL PUBLIC LICENSE
as published by the Free Software Foundation, either version 3
of the License, or (at your option) any later version.

## Intro
The Omega Project aims to develop a universal simulator accessible by registered
users over the json-rpc protocol. This allows the most users and developers to access
and control entities and subsystems via any programming language and transport protocol.

Omega consists of several subprojects:

* **Motel** - Movable Objects Tracking Encompassing Locations - Tracks locations,
eg coordinates w/ an orientation and movement strategy, in 3d cartesian space.
The location's movement strategy periodically updates the location's properties.
(eg along linear, elliptical paths, following another location, etc)

* **Users** - User registrations, sessions, permissions, groups, etc

* **Cosmos** - Manages heirarchies of cosmos entities, galaxies, solar systems,
stars, planets, moons, asteroids, etc. Each cosmos entity is associated with
a location tracked by Motel.

* **Manufactured** - Manages player controlled and constructed entities,
ships, stations, etc. Similar to the cosmos subsystem, each manufactured entity
is associated with a location managed by Motel.

* **Missions** - Manages high level recurring events and goals. Privileged
users are permitted to create sequences of checks/operations which query/impact
other subsystems.

* **Stats** - Provides access to overall user and universe statistics. Other
subsystems may write to stats here and/or read stats to modify operations.

* **Omega** - Convenience utilities to bind the various server side subsystems
together, and provides simple mechanisms which to invoke functionality via a remote client.
This includes a simple dsl which can be used to setup a simulation as well as an
event based interface which to query/manipulate entities.

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
[RJR](http://rubydoc.info/github/movitto/rjr/frames)
allows Omega to serve JSON-RPC requests over many protocols.
Currently the default server listens for requests via TCP, HTTP,
Websockets, and AMQP. All a client has to do is send a string
containing a json request to the server via any of these protocols.

    # A simplified example (authentication has been disabled)

    $ curl -X POST http://localhost:8888 -d \
       '{"jsonrpc":"2.0", "method":"cosmos::get_entities",
         "params":["of_type", "Cosmos::SolarSystem"], "id":"123"}'

    => {"jsonrpc":"2.0","id":"123","result":[{"json_class":"Cosmos::SolarSystem","data":{"name":"..."}}]}
   
RJR provides mechanisms to invoke client requests very simply via Ruby:

    # A more complete example, involving authentication
    login_user = Users::User.new :id => 'me', :password => 'secret'
    node = RJR::Nodes::AMQP.new :node_id => 'client', :broker   => 'localhost'

    # omega-queue is the name of the server side amqp queue
    session = node.invoke('omega-queue', 'users::login', login_user)
    node.headers['session_id'] = session.id

    node.invoke('omega-queue', 'cosmos::get_entities', 'of_type', 'Cosmos::SolarSystem')
    # => [#<Cosmos::SolarSystem:0x00AABB...>,...]


Once authenticated, the client may invoke a variety of requests to create,
retrieve, and update server side entities, depending on roles they have
been assigned and their corresponding privileges / permissions. Some methods
have additional restrictions to limit user access, see the api documentation
in the [API](file:API) file and source code (see 'generating documentation' below) for more info

## Running the clients

Omega provides a few client helper utilities in the bin/util directory as
well as many various sample data sets in the examples/ dir.

These are meant to assist in the creation of users and the manipulation of
entities they own, and to retrieve cosmos and other entities. 

To invoke, simply run the scripts right from the command line, specifying
'-h' or '--help' for extended usage.

See the [CLIENT_HOWTO](file:examples/CLIENT_HOWTO.md) for more info

## Web Frontend

A static web frontend and js Omega client is provided in the site/ dir.
This uses [Middleman](http://middlemanapp.com/) to generate static html/js
content from templates.

Two rake tasks are provided to simplify usage:
* rake site:preview - will start a light / live / local webserver which to
  access the site and preview changes on the fly
* rake site:build - generates static content which to deploy to a production
  webserver such as apache or nginx. This server should be configured to serve
  the static content as well as proxy JSON-RPC requests to the Omega Server
  as they arrive from the javascript client.

See the omega-conf project for configuration files and utility scripts / recipes
which can be used to assist the deployment of an omega server and js frontend.

The static site requires a few files such as images and mesh data not shipped
with the source code. Again see the omega-conf project for how to get these
content packs.

## Using

Generate documentation via

  rake yard

To run test suite:

  rake spec

## Authors
 Mohammed Morsi <mo@morsi.org>
