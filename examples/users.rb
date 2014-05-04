#!/usr/bin/ruby
# Creates an example user and a few ships/stations belonging
# to them based on command line args
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'

require 'omega/client/dsl'
require 'rjr/nodes/amqp'
require 'motel/location'

include Omega::Client::DSL
include Motel

USER_NAME  = ARGV.shift
PASSWORD   = ARGV.shift
STARTING_SYSTEM = ARGV.shift
ROLENAMES   = *ARGV

RJR::Logger.log_level= ::Logger::DEBUG

dsl.rjr_node = RJR::Nodes::AMQP.new(:node_id => 'seeder', :broker => 'localhost')
login 'admin', 'nimda'

u = user USER_NAME, PASSWORD do |u|
  ROLENAMES.each { |rn|
    role rn.intern
  }
end

starting_system = system(STARTING_SYSTEM)
starting_loc    = loc(rand_invert(constraint('system_entity', 'position')))

station(USER_NAME + "-manufacturing-station1") do |station|
  station.type         = :manufacturing
  station.user_id      = USER_NAME
  station.solar_system = starting_system
  station.location     = starting_loc.clone
  #station.location.ms  = station_orbit :speed => 0.004
end

ship(USER_NAME + "-mining-ship1") do |ship|
  ship.type         = :mining
  ship.user_id      = USER_NAME
  ship.solar_system = starting_system
  ship.location     = starting_loc + [50000000, -50000000, 50000000]
end

ship(USER_NAME + "-corvette-ship1") do |ship|
  ship.type         = :corvette
  ship.user_id      = USER_NAME
  ship.solar_system = starting_system
  ship.location     = starting_loc + [-50000000, 50000000, -50000000]
end
