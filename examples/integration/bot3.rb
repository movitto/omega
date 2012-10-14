#!/usr/bin/ruby
# single integration test bot (rev 3)
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr'
require 'omega'

USER_NAME = ARGV.shift
PASSWORD = ARGV.shift

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

Omega::Client::User.login node, USER_NAME, PASSWORD

def start_miner(miner)
  puts "registering #{miner.id} events"
  miner.on_event('selected_resource') { |m,rs|
    puts "ship #{miner.id.bold.yellow} selected #{rs.id.bold.red}, moving to #{rs.entity.location.to_s}"
  }
  miner.on_event('resource_collected') { |*args|
    puts "ship #{miner.id.bold.yellow} collected #{args[3]} of resource #{args[2].resource.id.bold.red}"
  }
  miner.on_event('mining_stopped') { |*args|
    puts "ship #{miner.id.bold.yellow} stopped mining #{args[3].resource.id.bold.red} due to #{args[1]}"
  }
  miner.on_event('moving_to_station') { |m,st|
    puts "Miner #{m.id.bold.yellow} moving to station #{st.id.bold.yellow}"
  }
  miner.on_event('arrived_at_station') { |m|
    puts "Miner #{m.id.bold.yellow} arrived at station"
  }
  miner.on_event('transferred') { |m,st,r,q|
    puts "Miner #{m.id.bold.yellow} transferred #{q} of #{r.bold.red} to #{st.id.bold.yellow}"
  }
  miner.on_event('arrived_at_resource') { |m|
    puts "Miner #{m.id.bold.yellow} arrived at resource"
  }
  miner.on_event('no_more_resources') { |m|
    puts "Miner #{m.id.bold.yellow} could not find any more accessible resources"
  }
  miner.start
end

def start_corvette(corvette)
  puts "registering #{corvette.id} events"
  corvette.on_event('selected_next_system') { |c, s, jg|
    puts "corvette #{c.id.bold.yellow} traveling to system #{s.name} via jump gate @ #{jg.location}"
  }
  corvette.on_event('arrived_in_system') { |c|
    puts "corvette #{c.id.bold.yellow} arrived in system #{c.system_name.green}"
  }
  corvette.on_event('attacked') { |event, attacker,defender|
    puts "#{attacker.id.bold.yellow} attacked #{defender.id.bold.yellow}"
  }
  corvette.on_event('defended') { |event, attacker,defender|
    puts "#{defender.id.bold.yellow} attacked by #{attacker.id.bold.yellow}"
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
    puts "station #{f.id.bold.yellow} jumped to system #{f.system_name.green}"
  }
  factory.on_event('on_construction') { |f,e|
    puts "#{f.id.bold.yellow} constructed #{e.id.bold.yellow}"
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

Omega::Bot::Factory.owned_by(USER_NAME).each  { |f| start_factory  f }
Omega::Bot::Corvette.owned_by(USER_NAME).each { |c| start_corvette c }
Omega::Bot::Miner.owned_by(USER_NAME).each    { |m| start_miner    m }
node.join
