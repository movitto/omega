#!/usr/bin/ruby
# example bot, uses omega client api to automatically run ships and
# stations according to a simple algorithm
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'colored'

require 'omega'
require 'omega/client/entities/ship'
require 'omega/client/entities/station'
require 'omega/client/entities/user'
require 'rjr/nodes/tcp'

USER_NAME = ARGV.shift
PASSWORD  = ARGV.shift

#RJR::Logger.log_level = ::Logger::INFO

node = RJR::Nodes::TCP.new(:node_id => 'client', :host => 'localhost', :port => '9090')
Omega::Client::Trackable.node.rjr_node = node
Omega::Client::User.login USER_NAME, PASSWORD

##########################################

# Global event handlers & bot setup

def start_miner(miner)
  puts "registering #{miner.id} events"
  miner.handle(:selected_resource) { |m,e|
    puts "miner #{miner.id.bold.yellow} selected #{e.to_s} to mine"
  }
  miner.handle(:no_resources) { |m|
    puts "Miner #{m.id.bold.yellow} could not find any more accessible resources"
  }
  miner.handle(:resource_collected) { |*args|
    puts "ship #{miner.id.bold.yellow} collected #{args[3]} of resource #{args[2].resource.id.bold.red}"
  }
  miner.handle(:mining_stopped) { |*args|
    puts "ship #{miner.id.bold.yellow} stopped mining #{args[3].resource.id.bold.red} due to #{args[1]}"
  }
  miner.handle(:transferred) { |m,st,r,q|
    puts "Miner #{m.id.bold.yellow} transferred #{q} of #{r.bold.red} to #{st.id.bold.yellow}"
  }
  miner.start_bot
end

def start_corvette(corvette)
  puts "registering #{corvette.id} events"
  corvette.handle(:jumped) { |c|
    puts "corvette #{c.id.bold.yellow} jumped to system #{c.system_id.green}"
  }
  corvette.handle(:attacked) { |event, attacker,defender|
    puts "#{attacker.id.bold.yellow} attacked #{defender.id.bold.yellow}"
  }
  corvette.handle(:defended) { |event, attacker,defender|
    puts "#{defender.id.bold.yellow} attacked by #{attacker.id.bold.yellow}"
  }
  corvette.start_bot
end

def start_factory(factory)
  puts "registering #{factory.id} events"
  factory.handle(:jumped) { |f|
    puts "station #{f.id.bold.yellow} jumped to system #{f.system_id.green}"
  }
  factory.handle(:constructed) { |f,e|
    constructed = e.last
    puts "#{f.id.bold.yellow} constructed #{constructed.id.bold.yellow}"
    init_entity constructed

    if constructed.is_a?(Manufactured::Ship)
      if constructed.type == :mining
        factory.entity_type 'corvette'

      elsif constructed.type == :corvette
        factory.entity_type 'miner'

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

##########################################

# Run initialization loop so as to free station event handler
@init_queue = Queue.new
@init_cycle = Thread.new {
  while to_init = @init_queue.pop
    if to_init.is_a?(Omega::Client::Factory)
      start_factory(to_init)

    elsif to_init.is_a?(Omega::Client::Corvette)
      start_corvette(to_init)

    elsif to_init.is_a?(Omega::Client::Miner)
      start_miner(to_init)

    elsif to_init.is_a?(Manufactured::Station)
      start_factory(Omega::Client::Factory.get(to_init.id))

    elsif to_init.is_a?(Manufactured::Ship)
      if to_init.type == :mining
        start_miner(Omega::Client::Miner.get(to_init.id))

      elsif to_init.type == :corvette
        start_corvette(Omega::Client::Corvette.get(to_init.id))

      end
    end
  end
}

def init_entity(entity)
  @init_queue << entity
end

##########################################

# Load and start initial entities and block

#Omega::Client::Factory.owned_by(USER_NAME).each  { |f| init_entity f }
Omega::Client::Corvette.owned_by(USER_NAME).each { |c| init_entity c }
Omega::Client::Miner.owned_by(USER_NAME).each    { |m| init_entity m }
Omega::Client::Trackable.node.rjr_node.join
