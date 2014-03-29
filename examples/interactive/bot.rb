#!/usr/bin/ruby

require 'omega'
require 'omega/client/entities/ship'
require 'omega/client/entities/station'

include Omega::Client

require 'omega/client/boilerplate'

Trackable.node.rjr_node = dsl.rjr_node

#users = ['Anubis', 'Aten', 'Horus', 'Imhotep', 'Ptah']
uid = ARGV.shift

login uid, uid

# TODO incorporate corvettes into this

Factory.owned_by(uid).each { |factory|
  factory.handle(:construction_complete) { |f,evnt,st,entity|
    entity.start_bot
  }

  factory.entity_type 'miner'
  factory.start_bot
}

Miner.owned_by(uid).each { |miner|
  miner.start_bot
}

dsl.rjr_node.join
