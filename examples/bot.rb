#!/usr/bin/ruby
# single integration test bot (rev 4)
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr'
require 'omega'

USER_NAME = ARGV.shift
PASSWORD = ARGV.shift

#RJR::Logger.log_level = ::Logger::INFO

Omega::Client::Node.client_username = USER_NAME
Omega::Client::Node.client_password = PASSWORD

#node = RJR::AMQPNode.new(:node_id => 'client', :broker => 'localhost')
Omega::Client::Node.node = RJR::TCPNode.new(:node_id => 'client', :host => 'localhost', :port => '9090')

def start_miner(miner)
  puts "registering #{miner.id} events"
  miner.handle_event(:selected_resource) { |m,e|
    puts "miner #{miner.id.bold.yellow} selected #{e.to_s} to mine"
  }
  miner.handle_event(:no_resources) { |m|
    puts "Miner #{m.id.bold.yellow} could not find any more accessible resources"
  }
  miner.handle_event(:resource_collected) { |*args|
    puts "ship #{miner.id.bold.yellow} collected #{args[3]} of resource #{args[2].resource.id.bold.red}"
  }
  miner.handle_event(:mining_stopped) { |*args|
    puts "ship #{miner.id.bold.yellow} stopped mining #{args[3].resource.id.bold.red} due to #{args[1]}"
  }
  miner.handle_event(:transferred) { |m,st,r,q|
    puts "Miner #{m.id.bold.yellow} transferred #{q} of #{r.bold.red} to #{st.id.bold.yellow}"
  }
  miner.start_bot
end

def start_corvette(corvette)
  puts "registering #{corvette.id} events"
  corvette.handle_event(:jumped) { |c|
    puts "corvette #{c.id.bold.yellow} jumped to system #{c.system_name.green}"
  }
  corvette.handle_event(:attacked) { |event, attacker,defender|
    puts "#{attacker.id.bold.yellow} attacked #{defender.id.bold.yellow}"
  }
  corvette.handle_event(:defended) { |event, attacker,defender|
    puts "#{defender.id.bold.yellow} attacked by #{attacker.id.bold.yellow}"
  }
  corvette.start_bot
end

def start_factory(factory)
  puts "registering #{factory.id} events"
  factory.handle_event(:jumped) { |f|
    puts "station #{f.id.bold.yellow} jumped to system #{f.system_name.green}"
  }
  factory.handle_event(:constructed) { |f,e|
    puts "#{f.id.bold.yellow} constructed #{e.id.bold.yellow}"
    if e.is_a?(Manufactured::Station)
      start_factory Omega::Client::Factory.get(e.id)

    elsif e.is_a?(Manufactured::Ship)
      if e.type == :mining
        factory.entity_type 'corvette'
        start_miner Omega::Client::Miner.get(e.id)

      elsif e.type == :corvette
        factory.entity_type 'miner'
        start_corvette Omega::Client::Corvette.get(e.id)

      end
    end
  }

  if @first_factory.nil?
    factory.entity_type 'factory'
    @first_factory = factory
  else
    factory.entity_type 'miner'
    factory.pick_system
  end

  factory.start_bot
end

Omega::Client::Factory.owned_by(USER_NAME).each  { |f| start_factory  f }
Omega::Client::Corvette.owned_by(USER_NAME).each { |c| start_corvette c }
Omega::Client::Miner.owned_by(USER_NAME).each    { |m| start_miner    m }
Omega::Client::Node.join
