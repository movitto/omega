#!/usr/bin/ruby
# single integration test user
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'

include Omega::DSL
include Motel

USER_NAME  = ARGV.shift
PASSWORD   = ARGV.shift
STARTING_SYSTEM = ARGV.shift
ROLENAMES   = *ARGV

RJR::Logger.log_level= ::Logger::INFO
login 'admin',  :password => 'nimda'

u = user USER_NAME, :password => PASSWORD do
  ROLENAMES.each { |rn|
    role rn.intern
  }
end

starting_system = system(STARTING_SYSTEM)

alliance USER_NAME + "-alliance", :members => [u]

station(USER_NAME + "-manufacturing-station1") do |station|
  station.type     = :manufacturing
  station.user_id  = USER_NAME
  station.solar_system = starting_system
  station.location = Location.new(:x => 100,  :y=> 100,  :z => 100)
  #station.location = Location.new(:x => -100, :y=> -100, :z => -100)
end

mining   = ship(USER_NAME + "-mining-ship1") do |ship|
             ship.type     = :mining
             ship.user_id  = USER_NAME
             ship.solar_system = starting_system
             #ship.location = Location.new(:x => 30, :y=> -20, :z => 20)
             ship.location = Location.new(:x => 20, :y=> 40, :z => 40)
           end

corvette = ship(USER_NAME + "-corvette-ship1") do |ship|
             ship.type     = :corvette
             ship.user_id  = USER_NAME
             ship.solar_system = starting_system
             ship.location = Location.new(:x => -150,  :y=> 0,  :z => -150)
             #ship.location = Location.new(:x => -200, :y=> -150, :z => 100)
           end
