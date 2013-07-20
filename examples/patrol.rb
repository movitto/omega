#!/usr/bin/ruby
# patrol example, creates some data and runs simple patrol route algorithm
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'colored'

require 'omega'
require 'omega/client/dsl'
require 'omega/client/entities/ship'
require 'omega/client/entities/user'
require 'rjr/nodes/tcp'

include Motel
include Omega::Client::DSL

#RJR::Logger.log_level = ::Logger::INFO

node = RJR::Nodes::TCP.new(:node_id => 'client', :host => 'localhost', :port => '9090')
dsl.rjr_node = node
Omega::Client::Trackable.node.rjr_node = node
login 'admin', 'nimda'

####################### create environment

galaxy 'Zeus' do |g|
  system 'Athena',    'HR1925', :location => rand_location
  system 'Aphrodite', 'V866',   :location => rand_location
  system 'Philo',     'HU1792', :location => rand_location
end

athena    = system('Athena')
aphrodite = system('Aphrodite')
philo     = system('Philo')

jump_gate athena,    aphrodite, :location => Location.new(:x => 150, :y => 150, :z => 150)
jump_gate athena,    philo,     :location => rand_location
jump_gate aphrodite, athena,    :location => rand_location
jump_gate aphrodite, philo,     :location => rand_location
jump_gate philo,     aphrodite, :location => rand_location

####################### create users

user 'player', 'reyalp' do |u|
  role :regular_user
end

user 'enemy', 'ymene' do |u|
  role :regular_user
end

####################### create ships

ship("player-corvette1") do |ship|
  ship.type         = :corvette
  ship.user_id      = 'player'
  ship.solar_system = athena
  ship.location     = Location.new(:x => 0, :y => 0, :z => 0)
end

ship("enemy-corvette1") do |ship|
  ship.type         = :corvette
  ship.user_id      = 'enemy'
  ship.solar_system = athena
  ship.location     = Location.new(:x => 50, :y => 50, :z => 50)
end

##########################################

# Load and start initial entities and block

Omega::Client::Corvette.owned_by('player').each { |corvette|
  sputs "registering #{corvette.id} events"
  corvette.handle(:jumped) { |c|
    sputs "corvette #{c.id.bold.yellow} jumped to system #{c.system_id.green}"
  }
  corvette.handle(:attacked) { |c,event, defender|
    sputs "#{c.id.bold.yellow} attacked #{defender.id.bold.yellow}"
  }
  corvette.handle(:defended) { |c,event, attacker|
    sputs "#{c.id.bold.yellow} attacked by #{attacker.id.bold.yellow}"
  }
  corvette.start_bot
}

Omega::Client::Trackable.node.rjr_node.join
