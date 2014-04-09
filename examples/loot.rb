#!/usr/bin/ruby
# Example to demonstrate loot collection
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'colored'

require 'omega'
require 'omega/client/dsl'
require 'omega/client/entities/corvette'
require 'rjr/nodes/tcp'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

node = RJR::Nodes::TCP.new(:node_id => 'client', :host => 'localhost', :port => '9090')
dsl.rjr_node = node
Omega::Client::Trackable.node.rjr_node = node # XXX
login 'admin', 'nimda'

####################### create environment
galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925', :location => Location.new(:x => 240, :y => -360, :z => 110) do |sys|
  end
end

starting_system = system('Athena')

####################### create users

user 'player', 'reyalp' do |u|
  role :regular_user
end

user 'enemy', 'ymene' do |u|
  role :regular_user
end

####################### create ships

ship("player-corvette-ship1") do |ship|
  ship.type     = :corvette
  ship.user_id  = 'player'
  ship.solar_system = starting_system
  ship.location = Location.new(:x => -150,  :y=> 0,  :z => -150)
end

miner =
  ship("enemy-miner-ship1") do |ship|
    ship.type     = :mining
    ship.user_id  = 'enemy'
    ship.solar_system = starting_system
    ship.location = Location.new(:x => -140,  :y=> 0,  :z => -140)
    ship.add_resource Cosmos::Resource.new(:id=> 'metal-steel', :quantity=> 50)
  end

# TODO logout admin / login player ?

####################### attack ship / collect loot

corvette = Omega::Client::Corvette.get('player-corvette-ship1')
corvette.handle(:attacked_stop) do |*args|
  loot = dsl.invoke 'manufactured::get', 'with_id', 'enemy-miner-ship1-loot'
  corvette.collect_loot loot
  puts "Corvette Resources #{corvette.resources}".green
  dsl.rjr_node.halt
end

#puts "Miner Resources #{miner.resources}".green
puts "Corvette Resources #{corvette.resources}".green
corvette.attack miner

dsl.rjr_node.join
