#!/usr/bin/ruby
#
# A simple opponent bot to play against in the tournament simulation
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'optparse'

require 'omega'
require 'omega/client/entities/miner'
require 'omega/client/entities/corvette'
require 'omega/client/entities/station'

include Omega::Client

conf = {:user   => nil,
        :mining => false,
        :patrol => false}
optparse = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this help screen') do
    puts opts
    exit
  end

  opts.on('-u', '--user ID', 'user to log in as') do |u|
    conf[:user] = u
  end

  opts.on('-m', '--mining', 'run mining bots') do
    conf[:mining] = true
  end

  opts.on('-p', '--patrol', 'run patrol bots') do
    conf[:patrol] = true
  end
end

optparse.parse!

if conf[:user].nil? || (!conf[:mining] && !conf[:patrol])
  puts "Must specify user and bots to run"
  exit 1
end

UID = conf[:user]

node = RJR::Nodes::TCP.new(:node_id => UID,
                           :host    => 'localhost',
                           :port    => '9090')
Trackable.node.rjr_node = node

Trackable.node.login UID, 'password'

# retrieve stations from server
Factory.owned_by(UID)

Miner.owned_by(UID).each { |miner|
  miner.start_bot
} if conf[:mining]

Corvette.owned_by(UID).each { |corvette|
  corvette.start_bot
} if conf[:patrol]

Omega::Client::Trackable.node.rjr_node.join
