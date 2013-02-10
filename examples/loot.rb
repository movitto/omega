#!/usr/bin/ruby
# simple example to demonstrate loot collection
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

node = RJR::TCPNode.new(:node_id => 'client', :host => 'localhost', :port => '9090')
login node, 'admin', 'nimda'

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
  ship("enemy-miner-ship1",
        :resources => {'metal-steel' => 100}) do |ship|
    ship.type     = :mining
    ship.user_id  = 'enemy'
    ship.solar_system = starting_system
    ship.location = Location.new(:x => -140,  :y=> 0,  :z => -140)
  end

# TODO logout admin / login player ?

####################### attack ship / collect loot

corvette = Omega::Client::Corvette.get('player-corvette-ship1')
corvette.handle_event(:attacked_stop) do |*args|
  loot = Omega::Client::Node.invoke_request 'manufactured::get',
                            'with_id', 'enemy-miner-ship1-loot',
                                           :include_loot, true
  corvette.collect_loot loot
  puts "Corvette Resources #{corvette.resources}".green
end

#puts "Miner Resources #{miner.resources}".green
puts "Corvette Resources #{corvette.resources}".green
corvette.attack miner

Omega::Client::Node.join
