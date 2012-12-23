#!/usr/bin/ruby
# single integration test bot (rev 4)
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr'
require 'omega'

USER_NAME = ARGV.shift
PASSWORD = ARGV.shift

RJR::Logger.log_level = ::Logger::INFO

Omega::Client::Node.client_username = USER_NAME
Omega::Client::Node.client_password = PASSWORD

#node = RJR::AMQPNode.new(:node_id => 'client', :broker => 'localhost')
Omega::Client::Node.node = RJR::TCPNode.new(:node_id => 'client', :host => 'localhost', :port => '9090')

def start_miner(miner)
  puts "registering #{miner.id} events"
  miner.handle_event('selected_resource') { |m,rs|
    puts "ship #{miner.id.bold.yellow} selected #{rs.id.bold.red}, moving to #{rs.entity.location.to_s}"
  }
  miner.handle_event('resource_collected') { |*args|
    puts "ship #{miner.id.bold.yellow} collected #{args[3]} of resource #{args[2].resource.id.bold.red}"
  }
  miner.handle_event('mining_stopped') { |*args|
    puts "ship #{miner.id.bold.yellow} stopped mining #{args[3].resource.id.bold.red} due to #{args[1]}"
  }
  miner.handle_event('moving_to_station') { |m,st|
    puts "Miner #{m.id.bold.yellow} moving to station #{st.id.bold.yellow}"
  }
  miner.handle_event('arrived_at_station') { |m|
    puts "Miner #{m.id.bold.yellow} arrived at station"
  }
  miner.handle_event('transferred') { |m,st,r,q|
    puts "Miner #{m.id.bold.yellow} transferred #{q} of #{r.bold.red} to #{st.id.bold.yellow}"
  }
  miner.handle_event('arrived_at_resource') { |m|
    puts "Miner #{m.id.bold.yellow} arrived at resource"
  }
  miner.handle_event('no_more_resources') { |m|
    puts "Miner #{m.id.bold.yellow} could not find any more accessible resources"
  }
  miner.start_bot
end

def start_corvette(corvette)
  puts "registering #{corvette.id} events"
  corvette.handle_event('selected_next_system') { |c, s, jg|
    puts "corvette #{c.id.bold.yellow} traveling to system #{s.name} via jump gate @ #{jg.location}"
  }
  corvette.handle_event('arrived_in_system') { |c|
    puts "corvette #{c.id.bold.yellow} arrived in system #{c.system_name.green}"
  }
  corvette.handle_event('attacked') { |event, attacker,defender|
    puts "#{attacker.id.bold.yellow} attacked #{defender.id.bold.yellow}"
  }
  corvette.handle_event('defended') { |event, attacker,defender|
    puts "#{defender.id.bold.yellow} attacked by #{attacker.id.bold.yellow}"
  }
  corvette.start_bot
end

def start_factory(factory)
  puts "registering #{factory.id} events"
  factory.handle_event('jumped') { |f|
    puts "station #{f.id.bold.yellow} jumped to system #{f.system_name.green}"
  }
  factory.handle_event('on_construction') { |f,e|
    puts "#{f.id.bold.yellow} constructed #{e.id.bold.yellow}"
    if e.is_a?(Manufactured::Station)
      #factory.entity_type 'miner'
      start_factory Omega::Bot::Factory.get(e.id)

    elsif e.is_a?(Manufactured::Ship)
      if e.type == :mining
        factory.entity_type 'corvette'
        start_miner Omega::Bot::Miner.get(e.id)

      elsif e.type == :corvette
        factory.entity_type 'miner'
        start_corvette Omega::Bot::Corvette.get(e.id)

      end
    end
  }

  unless @first_factory_constructed
    factory.entity_type 'factory'
    factory.start_bot
  else
    factory.entity_type 'miner'
  end
  @first_factory_constructed = true
end

Omega::Client::Factory.owned_by(USER_NAME).each  { |f| start_factory  f }
Omega::Client::Corvette.owned_by(USER_NAME).each { |c| start_corvette c }
Omega::Client::Miner.owned_by(USER_NAME).each    { |m| start_miner    m }
Omega::Client::Node.join
