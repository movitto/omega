#!/usr/bin/ruby
# Registers some example hooks with an omega-server
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega'
require 'omega/client/dsl'
require 'missions/dsl'
require 'rjr/nodes/amqp'

include Omega::Client::DSL
include Missions::DSL::Client

dsl.rjr_node = RJR::Nodes::AMQP.new(:node_id => 'seeder', :broker => 'localhost')
login 'admin', 'nimda'

STARTING_SYSTEM = system(ARGV.shift)

# register post-user creation hooks
# TODO set locations
create_corvette =
  missions_event_handler('registered_user', :event_create_entity,
                         :entity_type => 'Manufactured::Ship',
                         :type => 'corvette', :solar_system => STARTING_SYSTEM)

create_miner =
  missions_event_handler('registered_user', :event_create_entity,
                         :entity_type => 'Manufactured::Ship',
                         :type => 'mining', :solar_system => STARTING_SYSTEM)

create_station =
  missions_event_handler('registered_user', :event_create_entity,
                         :entity_type => 'Manufactured::Station',
                         :type => 'manufacturing', :solar_system => STARTING_SYSTEM)

# TODO add privilege to user to view cosmos entities

invoke 'missions::add_hook', create_corvette
invoke 'missions::add_hook', create_miner
invoke 'missions::add_hook', create_station
