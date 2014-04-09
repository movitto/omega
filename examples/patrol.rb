#!/usr/bin/ruby
# patrol example, creates some data and runs simple patrol route algorithm
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'colored'

require 'omega'
require 'omega/client/dsl'
require 'omega/client/entities/corvette'
require 'omega/client/entities/user'
require 'rjr/nodes/tcp'

include Motel
include Omega::Client::DSL

CORVETTES = 5
SIZE = 300

#RJR::Logger.log_level = ::Logger::INFO

node = RJR::Nodes::TCP.new(:node_id => 'client', :host => 'localhost', :port => '9090')
dsl.rjr_node = node
Omega::Client::Trackable.node.rjr_node = node
login 'admin', 'nimda'

####################### create environment

galaxy 'Zeus' do |g|
  system 'Athena',    'HR1925', :location => rand_location(:max => SIZE)
  system 'Aphrodite', 'V866',   :location => rand_location(:max => SIZE)
  system 'Philo',     'HU1792', :location => rand_location(:max => SIZE)
end

athena    = system('Athena')
aphrodite = system('Aphrodite')
philo     = system('Philo')

jump_gate athena,    aphrodite, :location => rand_location(:max => SIZE)
jump_gate athena,    philo,     :location => rand_location(:max => SIZE)
jump_gate aphrodite, athena,    :location => rand_location(:max => SIZE)
jump_gate aphrodite, philo,     :location => rand_location(:max => SIZE)
jump_gate philo,     aphrodite, :location => rand_location(:max => SIZE)

####################### create users

user 'player', 'reyalp' do |u|
  role :regular_user
end

user 'enemy', 'ymene' do |u|
  role :regular_user
end

####################### create ships

0.upto(CORVETTES) do |i|
  starting_system =
    case rand(3)
    when 0 then athena
    when 1 then aphrodite
    when 2 then philo
    end

  ship("player-corvette#{i}") do |ship|
    ship.type         = :corvette
    ship.user_id      = 'player'
    ship.solar_system = starting_system
    ship.location     = rand_location(:max => SIZE)
  end

  ship("enemy-corvette#{i}") do |ship|
    ship.type         = :corvette
    ship.user_id      = 'enemy'
    ship.solar_system = starting_system
    ship.location     = rand_location(:max => SIZE)
  end
end

##########################################

# Load and start initial entities and block

Omega::Client::Corvette.get_all.each { |corvette|
  sputs "registering #{corvette.id} events"
  corvette.handle(:selected_system) { |c, system_id, jg|
    sputs "corvette #{c.id.bold.yellow} selected system #{system_id.green}"
  }
  corvette.handle(:jumped) { |c|
    sputs "corvette #{c.id.bold.yellow} jumped to system #{c.system_id.green}"
  }
  corvette.handle(:attacked) { |c,event, attacker, defender|
    sputs "#{c.id.bold.yellow} attacked #{defender.id.bold.yellow}"
  }
  corvette.handle(:attacked_stop) { |c,event, attacker, defender|
    sputs "#{c.id.bold.yellow} stopped attacking #{defender.id.bold.yellow}"
  }
  corvette.handle(:defended) { |c,event, defender, attacker|
    sputs "#{c.id.bold.yellow} defendend against #{attacker.id.bold.yellow}"
  }
  corvette.handle(:defended_stop) { |c,event, defender, attacker|
    sputs "#{c.id.bold.yellow} stopped defending against #{attacker.id.bold.yellow}"
  }
  corvette.handle(:destroyed_by) { |c,event, defender, attacker|
    sputs "#{c.id.bold.yellow} destroyed by #{attacker.id.bold.yellow}"
  }
  corvette.start_bot
}

Omega::Client::Trackable.node.rjr_node.join
