#!/usr/bin/ruby
# mining example, creates some data and runs simple miner bot algorithm
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

MINERS = 1

#RJR::Logger.log_level = ::Logger::INFO

node = RJR::Nodes::TCP.new(:node_id => 'client', :host => 'localhost', :port => '9090')
dsl.rjr_node = node
Omega::Client::Trackable.node.rjr_node = node
login 'admin', 'nimda'

####################### create environment

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925', :location => rand_location do |sys|
    asteroid gen_uuid, :location => rand_location do |ast|
      resource :resource => rand_resource, :quantity => 5000 
    end

    asteroid gen_uuid, :location => rand_location do |ast|
      resource :resource => rand_resource, :quantity => 5000 
      resource :resource => rand_resource, :quantity => 5000 
    end
  end
end

starting_system = system('Athena')

####################### create user

user 'player', 'reyalp' do |u|
  role :regular_user
end

####################### create miners / nearby station

0.upto(MINERS) do |i|
  ship("player-miner1") do |ship|
    ship.type         = :mining
    ship.user_id      = 'player'
    ship.solar_system = starting_system
    ship.location     = rand_location
  end
end

station("player-station1") do |station|
  station.type     = :manufacturing
  station.user_id  = 'player'
  station.solar_system = starting_system
  station.location = Location.new(:x => 100,  :y=> 100,  :z => 100)
end

# TODO logout admin / login player ?

##########################################

# Load and start initial entities and block

Omega::Client::Station.owned_by('player')
Omega::Client::Miner.owned_by('player').each { |miner|
  sputs "registering #{miner.id} events"
  miner.handle(:selected_resource) { |m,a|
    sputs "miner #{m.id.bold.yellow} selected #{a.to_s} to mine"
  }
  miner.handle(:no_resources) { |m|
    sputs "miner #{m.id.bold.yellow} could not find any more accessible resources, idling"
  }
  miner.handle(:resource_collected) { |m,evnt,sh,res,q|
    sputs "miner #{m.id.bold.yellow} collected #{q} of resource #{res.id.bold.red}"
  }
  miner.handle(:mining_stopped) { |m,evnt,sh,res,reason|
    sputs "miner #{m.id.bold.yellow} stopped mining resource #{res.id.bold.red} due to #{reason}"
  }
  miner.handle(:no_stations) { |m|
    sputs "miner #{m.id.bold.yellow} could not find stations, idling"
  }
  miner.handle(:transferred_to) { |m,st,r|
    sputs "miner #{m.id.bold.yellow} transferred #{r.quantity} of #{r.to_s.bold.red} to #{st.id.bold.yellow}"
  }
  miner.start_bot
}

Omega::Client::Trackable.node.rjr_node.join
