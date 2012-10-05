#!/usr/bin/ruby
# single integration test bot (rev 3)
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr'
require 'omega'
require 'omega/client/user'
require 'omega/client/ship'
require 'omega/client/station'
#require 'omega/client/cosmos_entity'
require 'omega/bot/miner'

#RJR::Logger.log_level = ::Logger::DEBUG

node = RJR::AMQPNode.new(:node_id => 'client', :broker => 'localhost')

#RJR::Signals.setup
#Signal.trap("INT") {
#  puts "Signal detected, halting"
#  node.halt
#}
#Signal.trap("USR1") {
# # dump a slew of internal info
# puts "Status Check:"
# puts "Event Machine Running? #{EMAdapter.running?}"
# terminate = ThreadPool2Manager.thread_pool.instance_variable_get(:@terminate)
# puts "Thread Pool Running? #{ThreadPool2Manager.running?} (#{terminate})"
# workers = ThreadPool2Manager.thread_pool.instance_variable_get(:@worker_threads)
# work_q  = ThreadPool2Manager.thread_pool.instance_variable_get(:@work_queue)
# puts "Thread Pool Workers: #{workers.size}/#{work_q.size} - #{workers.collect { |w| w.status }.join(",")}"
#}

Omega::Client::User.login node, "admin", "nimda"
#Omega::Client::User.get_all.each { |u|
#  puts "got user #{u.id}"
#  u.refresh_every(3) { |e|
#    puts "updated user #{e.id}"
#  }
#}
#Omega::Client::Ship.get_all.each { |s|
#  puts "got ship #{s.id}"
#  s.on_movement_of(10) { |loc|
#    puts "ship #{s.id} location #{loc.id} moved to #{loc}"
#  }
#  s.on_event('resource_collected') { |*args|
#    puts "ship #{s.id} resource collected #{args.join(", ")}"
#  }
#  s.on_event('mining_stopped') { |*args|
#    puts "ship #{s.id} mining stopped #{args.join(", ")}"
#  }
#}

#station = Omega::Client::Station.get('Anubis-manufacturing-station1')
#station.jump_to 'Philo'

miner = Omega::Bot::Miner.get('Anubis-mining-ship1')

puts "registering #{miner.id} events"
miner.on_event('resource_collected') { |*args|
  puts "ship #{miner.id} collected #{args[3]} of resource #{args[2].resource.id}"
}
miner.on_event('mining_stopped') { |*args|
  puts "ship #{miner.id} stopped mining #{args[3].resource.id} due to #{args[1]}"
}
miner.on_event('arrived_at_station') { |m|
  puts "Miner #{miner.id} arrived at station"
}
miner.on_event('arrived_at_resource') { |m|
  puts "Miner #{miner.id} arrived at resource"
}
miner.start

node.join
