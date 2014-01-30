#!/usr/bin/ruby
# A small demo for FLOSS weekly
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'

require 'omega'
require 'omega/client/dsl'
require 'rjr/nodes/tcp'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

#========================================== Login to Omega over TCP

dsl.rjr_node =
  RJR::Nodes::TCP.new(:node_id =>    'seeder',
                      :host    => 'localhost',
                      :port    =>        8181)
login 'admin', 'nimda'

#========================================== Universe:
galaxy 'Odin' do |g|
  system 'Loki', 'HR1925', :location => loc(950,-20,-230) do |sys|
  end
  system 'Thor',   'HU1792', :location => loc(-954,27,881)  do |sys|
    planet 'Freya', :movement_strategy =>
      orbit(:e => 0.65, :speed => 0.008, :p => 6000,
            :direction => random_axis(:orthogonal_to => [0,1,0]))
  end
end

loki    = system('Loki')
thor    = system('Thor')

jump_gate loki, thor,   :location => loc( 1050, 1050, 1050)
jump_gate thor, loki,   :location => loc(-1050, 1050,-1050)

#========================================== Users:

[['mmorsi', 'secret1', :corvette],
 ['nico',   'secret2', :transport],
 ['host1',  'secret3', :corvette],
 ['host2',  'secret4', :mining]].each { |args|
  username, pass, ship_type = *args
  coin_flip = ((rand * 2).floor == 0)
  starting_system = coin_flip ? loki : thor

  user = user username, pass do |u| role :regular_user end

  station("#{user.id}-station") do |station|
    station.type         = :manufacturing
    station.user_id      = user.id
    station.solar_system = starting_system
    station.location     = rand_location(:min => 1000, :max => 2000)
  end

  ship("#{user.id}-ship") do |ship|
    ship.type            = ship_type
    ship.user_id         = user.id
    ship.solar_system    = starting_system
    ship.location        = rand_location(:min => 1000, :max => 2000)
  end
}
