#!/usr/bin/ruby
# Creates an example user and a few ships/stations belonging
# to them based on command line args
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
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

station(USER_NAME + "-manufacturing-station1") do |station|
  station.type     = :manufacturing
  station.user_id  = USER_NAME
  station.solar_system = starting_system
  station.location = Location.new(:x   => -200, :y   => -150, :z   => -200,
                                  :orx =>  0,  :ory =>  0,  :orz =>  1)
  #station.location = Location.new(:x => -100, :y=> -100, :z => -100)
end

mining   = ship(USER_NAME + "-mining-ship1") do |ship|
             ship.type     = :mining
             ship.user_id  = USER_NAME
             ship.solar_system = starting_system
             ship.location = Location.new(:x => -150, :y=> -100, :z => -150,
             #ship.location = Location.new(:x   => 520, :y   => 940, :z   => 940,
                                          :orx =>  0,  :ory =>  0,  :orz =>  1)
           end

corvette = ship(USER_NAME + "-corvette-ship1") do |ship|
             ship.type     = :corvette
             ship.user_id  = USER_NAME
             ship.solar_system = starting_system
             ship.location = Location.new(:x => -200, :y=> -150, :z => 100,
             #ship.location = Location.new(:x   => -1150, :y   => 400, :z => -750,
                                          :orx =>  0,    :ory =>  0,  :orz =>  1)
           end
