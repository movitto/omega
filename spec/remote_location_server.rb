#!/usr/bin/ruby
# remote server implementation, test program for externat entity management
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

$:<< "lib"

require 'rubygems'
require 'motel'
require 'users'
require 'omega/roles'
require 'rjr/amqp_node'

require './spec/spec_helper'

#RJR::Logger.log_level = ::Logger::DEBUG

config = Omega::Config.load :amqp_broker => 'localhost'
config.node_id = 'remote_server'
config.set_config(Motel::RemoteLocationManager)

Users::RJRAdapter.init
Motel::RJRAdapter.init

local_node = RJR::LocalNode.new  :node_id => config.node_id
rlm = Users::User.new :id => config.remote_location_manager_user, :password => config.remote_location_manager_pass
rlmr = Users::Role.new :id => 'remote_location_manager',
                       :privileges =>
                         Omega::Roles::ROLES[:remote_location_manager].collect { |pe|
                           Users::Privilege.new(:id => pe[0], :entity_id => pe[1])
                         }
local_node.invoke_request('users::create_entity', rlm)
local_node.invoke_request('users::create_entity', rlmr)
local_node.invoke_request('users::add_role', rlm.id, 'remote_location_manager')

amqp_node  = RJR::AMQPNode.new   :node_id => config.node_id, :broker => config.amqp_broker

amqp_node.listen

sleep 3

session = local_node.invoke_request('users::login', rlm)
local_node.message_headers['session_id'] = session.id

loc3 = Motel::Location.new :id => 3, :movement_strategy => Motel::MovementStrategies::Stopped.instance,
                           :parent_id => 2, :remote_queue => 'motel-rrjr-test-queue'
local_node.invoke_request('motel::create_location', loc3)

amqp_node.join
