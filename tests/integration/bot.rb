#!/usr/bin/ruby
# single integration test bot
#
# give bot a station and a couple of ships in the specified system
# and instructions on how to build up from there
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'

include Omega::DSL

include Motel

USER_NAME = ARGV.shift
STARTING_SYSTEM = ARGV.shift

RJR::Logger.log_level= ::Logger::INFO
login 'admin',  :password => 'nimda'

starting_system = system(STARTING_SYSTEM)
$system_resources = []

starting_system.asteroids.each { |ast|
   $system_resources += resource_sources(ast)
}

def get_nearest_nondepleted_resource(ship)
  $system_resources.select { |sr| sr.quantity > 0 }.
                    sort { |a,b| (ship.location - a.entity.location) <=>
                                 (ship.location - b.entity.location) }.first
end

def move_to_and_mine_nearest_resource(ship)
  rs = get_nearest_nondepleted_resource(ship)
  ship(ship.id) do |ship|
    RJR::Logger.info "moving ship #{ship.id} to #{rs.entity.name} to mine #{rs.resource.id}(#{rs.quantity})"
    nl = rs.entity.location + [10, 10, 10]
    move_to (nl)
    subscribe_to :movement, :distance => (ship.location - nl - 20)  do |*args|
      RJR::Logger.info "ship #{ship.id} arrived at #{rs.entity.name}, starting to mine"
      @ship = ship
      start_mining rs
    end
    subscribe_to :resource_collected do |s, srs, q|
      rs.quantity -= q
    end
    subscribe_to :resource_depleted do |s,srs|
      RJR::Logger.info "resource depleted"
      clear_callbacks
      move_to_and_mine_nearest_resource(ship)
    end
  end
end

station(USER_NAME + "-manufacturing-station") do |station|
  station.type     = :manufacturing
  station.user_id  = USER_NAME
  station.solar_system = starting_system
  station.location = Location.new(:x => 200, :y=> 200, :z => 200)
end

miner = ship(USER_NAME + "-mining-ship1") do |ship|
          ship.type     = :mining
          ship.user_id  = USER_NAME
          ship.solar_system = starting_system
          ship.location = Location.new(:x => 0, :y=> 300, :z => -200)
        end

move_to_and_mine_nearest_resource(miner)

#ship(USER_NAME + "-frigate-ship1") do |ship|
#  ship.type     = :frigate
#  ship.user_id  = USER_NAME
#  ship.solar_system = starting_system
#  ship.location = Location.new(:x => 200, :y=> 300, :z => -200)
#
#  subscribe_to :movement, :distance => 25 do
#  end
#end
#
#ship(USER_NAME + "-corvette-ship1") do |ship|
#  ship.type     = :corvette
#  ship.user_id  = USER_NAME
#  ship.solar_system = starting_system
#  ship.location = Location.new(:x => 400, :y=> 300, :z => -200)
#
#  subscribe_to :movement, :distance => 25 do
#  end
#end

# run the bot until signaled
#$term_mutex = Mutex.new
#$term_cv    = ConditionVariable.new

Signal.trap("USR1") {
  stop
}

listen
join
