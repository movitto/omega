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
require 'omega/bot/corvette'
require 'omega/bot/factory'

#RJR::Logger.log_level = ::Logger::DEBUG

#node = RJR::AMQPNode.new(:node_id => 'client', :broker => 'localhost')
node = RJR::TCPNode.new(:node_id => 'client', :host => 'localhost', :port => '9090')

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
# puts "Thread Pool Running? #{ThreadPool2Manager.running?} (terminate: #{terminate})"
# workers = ThreadPool2Manager.thread_pool.instance_variable_get(:@worker_threads)
# work_q  = ThreadPool2Manager.thread_pool.instance_variable_get(:@work_queue)
# run_q   = ThreadPool2Manager.thread_pool.instance_variable_get(:@running_queue)
# puts "Thread Pool Workers: #{workers.size}/#{work_q.size} - #{workers.collect { |w| w.status }.join(",")}"
# puts "Run Queue: #{run_q.size}" #{run_q.select { |i| i.being_executed }.collect { |i| [i.timestamp, i.thread, i.handler] }}"
#}

Omega::Client::User.login node, "Anubis", "sibuna"

def start_miner(miner)
  puts "registering #{miner.id} events"
  miner.on_event('selected_resource') { |m,rs|
    puts "ship #{miner.id} selected #{rs.id}, moving to #{rs.entity.location}"
  }
  miner.on_event('resource_collected') { |*args|
    puts "ship #{miner.id} collected #{args[3]} of resource #{args[2].resource.id}"
  }
  miner.on_event('mining_stopped') { |*args|
    puts "ship #{miner.id} stopped mining #{args[3].resource.id} due to #{args[1]}"
  }
  miner.on_event('moving_to_station') { |m|
    puts "Miner #{m.id} moving to closest station"
  }
  miner.on_event('arrived_at_station') { |m|
    puts "Miner #{m.id} arrived at station"
  }
  miner.on_event('transferred') { |m,st,r,q|
    puts "Miner #{m.id} transferred #{q} of #{r} to #{st.id}"
  }
  miner.on_event('arrived_at_resource') { |m|
    puts "Miner #{m.id} arrived at resource"
  }
  miner.on_event('no_more_resources') { |m|
    puts "Miner #{m.id} could not find any more accessible resources"
  }
  miner.start
end

def start_corvette(corvette)
  puts "registering #{corvette.id} events"
  corvette.on_event('selected_next_system') { |c, s, jg|
    puts "corvette #{c.id} traveling to system #{s.name} via jump gate @ #{jg.location}"
  }
  corvette.on_event('arrived_in_system') { |c|
    puts "corvette #{c.id} arrived in system #{c.system_name}"
  }
  corvette.on_event('attacked') { |event, attacker,defender|
    puts "#{attacker.id} attacked #{defender.id}"
  }
  corvette.on_event('defended') { |event, attacker,defender|
    puts "#{defender.id} attacked by #{attacker.id}"
  }
  corvette.start
end

def start_factory(factory)
  unless @first_factory_constructed
    factory.construct_entity_type = 'factory'
    factory.stay_in_system = true
  else
    factory.construct_entity_type = 'miner'
  end
  @first_factory_constructed = true

  puts "registering #{factory.id} events"
  factory.on_event('jumped') { |f|
    puts "station #{f.id} jumped to system #{f.system_name}"
  }
  factory.on_event('on_construction') { |f,e|
    puts "#{f.id} constructed #{e.id}"
    if e.is_a?(Manufactured::Station)
      #factory.construct_entity_type = 'miner'
      start_factory Omega::Bot::Factory.get(e.id)

    elsif e.is_a?(Manufactured::Ship)
      if e.type == :mining
        factory.construct_entity_type = 'corvette'
        start_miner Omega::Bot::Miner.get(e.id)

      elsif e.type == :corvette
        factory.construct_entity_type = 'miner'
        start_corvette Omega::Bot::Corvette.get(e.id)

      end
    end
  }
  factory.start
end

Omega::Bot::Factory.owned_by('Anubis').each  { |f| start_factory  f }
Omega::Bot::Corvette.owned_by('Anubis').each { |c| start_corvette c }
Omega::Bot::Miner.owned_by('Anubis').each    { |m| start_miner    m }
node.join
