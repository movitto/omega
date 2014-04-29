## How to write an Omega client

In the examples/ directory you will find several scripts
using the Omega client interfaces to setup and manipulate
various data sets.

## Primary Simulation

The examples/universes/ directory contains a few definitions of universes
of various sizes and complexities created via the omega client dsl.

examples/user.rb is simple script that reads command line parameters
and creates a new user w/ a few initial entities in the specified system.

examples/bot.rb uses the credentials and entities defined in user.rb
as well as the omega client interface to manipulate / control entities
in accordance w/ simple algorithms

A typical workflow would be to
* startup the omega-server
* create a universe of the desired size using a script in
  the examples/universes directory
* create any number of users by running examples/user.rb a
  number of times w/ various arguments
* startup bots for those users but running examples/bot.rb
  w/ each users credentials. The bots will run so long as the
  process exists (if killed they can be resumed from where
  they last left off by simply running them again)

The examples/bot_test.rb script can be used in conjunction with
the bin/util/omega-monitor utility to view bot operations at a
high level interface using ncurses.

## Demo Scripts

examples/story.rb - contains many sample missions and story sequences/arcs
using classical mythology and literature as the source material.

The following scripts are completely self contained (eg setup a
universe, user, entities, and runs operations) to demo omega
functionality:

* construct.rb - demonstrates constructing an entity using a station
  and waiting until construction is complete
* loot.rb - demonstrates attacking a ship and collecting loot
* mining.rb - demonstrates a continuous mining operation with miners
  and a factory
* patrol.rb - demonstrates an inter-system patrol route

## Writing your own client

The Omega client has two seperate interfaces:

* Omega Client DSL - primarily a 'write' interface used to
create / setup server side entities

* Omega Client Interface - a more interactive api which
users can use instances of classes representing server-side 
objects and mixins providing functionality to transparently
query and manipulate those entities

Both interfaces require the user to initially create a rjr node as well
as supply user credentials to login to the server with. See the examples/
for how to do this in both instances.

Finally Omega provides a JSON-RPC 2.0 compliant interface so any client
written in any language should be able to query / manipulate data.
