#!/usr/bin/ruby
# Example to demonstrate entity construction
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'colored'

require 'omega'
require 'omega/client/dsl'
require 'omega/client/entities/station'
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

####################### create user

user 'player', 'reyalp' do |u|
  role :regular_user
end

####################### create station

station("player-manufacturing-station1") do |station|
  station.type     = :manufacturing
  station.user_id  = 'player'
  station.solar_system = starting_system
  station.location = Location.new(:x => 100,  :y=> 100,  :z => 100)
end

# TODO logout admin / login player ?

####################### construct entity

RJR::Logger.log_level= ::Logger::WARN

station = Omega::Client::Factory.get('player-manufacturing-station1')
station.handle(:partial_construction) do |e,st,en,pc|
  puts "#{st.id} partially constructed #{en.id} (#{pc*100}/100%)".green
end
station.handle(:construction_complete) do |e,st,en|
  puts "#{st.id} fully constructed #{en.id}".green
end

st,en =
  station.construct :entity_type => 'Ship',
                    :type  => :mining,
                    :id   => "player-mining-ship"

puts "#{st.id} constructing #{en.id}".blue

dsl.rjr_node.join
