#!/usr/bin/ruby
# Example to demonstrate entity construction
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'colored'

require 'omega'
require 'omega/client/dsl'
require 'omega/client/entities/factory'
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
  system 'Athena',    'HR1925'
  system 'Aphrodite', 'V866'
  system 'Philo',     'HU1792'
end

athena    = system('Athena')
aphrodite = system('Aphrodite')
philo     = system('Philo')

jump_gate athena,    aphrodite
jump_gate athena,    philo
jump_gate aphrodite, athena
jump_gate aphrodite, philo
jump_gate philo,     aphrodite

####################### create user

user 'player', 'reyalp' do |u|
  role :regular_user
end

####################### create station

$i = 1

station("player-manufacturing-station#{$i}") do |station|
  station.type     = :manufacturing
  station.user_id  = 'player'
  station.solar_system = athena
end

####################### logout admin / login player

logout
login 'player', 'reyalp'

####################### construct entity

RJR::Logger.log_level= ::Logger::WARN

def run_factory(station)
  factory = station.is_a?(Omega::Client::Factory) ? station :
            Omega::Client::Factory.get(station.id)

  factory.handle(:jumped) do |f|
    sputs "station #{f.id.bold.yellow} jumped to system #{f.system_id.green}"
  end

  factory.handle(:partial_construction) do |st,*args|
    puts "pc #{args}"
  end

  factory.handle(:construction_complete) do |st,*args|
    puts "#{st.id} constructed #{args[2].id}".blue
    run_factory args[2]
  end

  factory.handle(:construction_failed) do |st,*args|
    puts "cf #{args}"
    dsl.rjr_node.halt
  end

  #$i += 1
  #st,en =
  #  factory.construct :entity_type => 'Station',
  #                    :type  => :manufacturing,
  #                    :id   => "player-manufactuing-station#{$i}"

  #puts "#{st.id} constructing #{en.id}".blue

  factory.entity_type 'factory'
  factory.pick_system
  factory.start_bot
end

station = Omega::Client::Factory.get("player-manufacturing-station#{$i}")
run_factory station
dsl.rjr_node.join
