#!/usr/bin/ruby
# example bot, uses omega client api to automatically run ships and
# stations according to a simple algorithm
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
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
end

def start_corvette(corvette)
  sputs "registering #{corvette.id} events"
  corvette.handle(:jumped) { |c|
    sputs "corvette #{c.id.bold.yellow} jumped to system #{c.system_id.green}"
  }
  corvette.handle(:attacked) { |c,event, attacker, defender|
    sputs "#{c.id.bold.yellow} attacked #{defender.id.bold.yellow}"
  }
  corvette.handle(:defended) { |c,event, attacker, defender|
    sputs "#{c.id.bold.yellow} attacked by #{attacker.id.bold.yellow}"
  }
  corvette.start_bot
end

def start_factory(factory)
  sputs "registering #{factory.id} events"
  factory.handle(:jumped) { |f|
    sputs "station #{f.id.bold.yellow} jumped to system #{f.system_id.green}"
  }
  #factory.handle(:partial_construction) { |f,evnt,st,entity,percent|
  factory.handle(:construction_failed) { |f,evnt,st,entity|
    sputs "#{f.id.bold.yellow} construction failed"
  }
  factory.handle(:construction_complete) { |f,evnt,st,entity|
    sputs "#{f.id.bold.yellow} constructed #{entity.id.bold.yellow}"
    init_entity entity

    if entity.is_a?(Manufactured::Ship)
      if entity.type == :mining
        factory.entity_type 'corvette'

      elsif entity.type == :corvette
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

Omega::Client::Factory.owned_by(USER_NAME).each  { |f| init_entity f }
#Omega::Client::Corvette.owned_by(USER_NAME).each { |c| init_entity c }
Omega::Client::Miner.owned_by(USER_NAME).each    { |m| init_entity m }
Omega::Client::Trackable.node.rjr_node.join
