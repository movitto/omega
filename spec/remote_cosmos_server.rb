#!/usr/bin/ruby
# remote server implementation, test program for externat entity management
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

$:<< "lib"

require 'rubygems'
require 'motel'
require 'users'
require 'cosmos'
require 'omega/roles'
require 'rjr/amqp_node'

require './spec/spec_helper'

#RJR::Logger.log_level = ::Logger::INFO

config = Omega::Config.load :amqp_broker => 'localhost'
config.node_id = 'remote_server'
config.set_config(Cosmos::RemoteCosmosManager)

Users::RJRAdapter.init
Motel::RJRAdapter.init
Cosmos::RJRAdapter.init

local_node = RJR::LocalNode.new  :node_id => config.node_id
rcm = Users::User.new  :id => config.remote_cosmos_manager_user, :password => config.remote_cosmos_manager_pass
rcmr = Users::Role.new :id => 'remote_cosmos_manager',
                       :privileges =>
                         Omega::Roles::ROLES[:remote_cosmos_manager].collect { |pe|
                           Users::Privilege.new(:id => pe[0], :entity_id => pe[1])
                         }
local_node.invoke_request('users::create_entity', rcm)
local_node.invoke_request('users::create_entity', rcmr)
local_node.invoke_request('users::add_role', rcm.id, 'remote_cosmos_manager')

amqp_node  = RJR::AMQPNode.new   :node_id => config.node_id, :broker => config.amqp_broker

amqp_node.listen

sleep 3

session = local_node.invoke_request('users::login', rcm)
local_node.message_headers['session_id'] = session.id

gal2 = Cosmos::Galaxy.new(:name => 'gal2', :location => Motel::Location.new(:id => 'g2'))
sys1 = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => 's1')
sys2 = Cosmos::SolarSystem.new :name => 'sys2', :remote_queue => 'cosmos-rrjr-test-queue', :location => Motel::Location.new(:id => 's2')

local_node.invoke_request('cosmos::create_entity', gal2, :universe)
local_node.invoke_request('cosmos::create_entity', sys1, 'gal1')
local_node.invoke_request('cosmos::create_entity', sys2, 'gal1')

Signal.trap("USR1") {
  exit
}

amqp_node.join
