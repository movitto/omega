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

#RJR::Logger.log_level = ::Logger::INFO

config = Omega::Config.load :amqp_broker => 'localhost'
config.node_id = 'remote_server'

Motel::RemoteLocationManager.user      = config.remote_location_manager_user
Motel::RemoteLocationManager.password  = config.remote_location_manager_pass

Users::RJRAdapter.init
Motel::RJRAdapter.init

rlm  = Omega::Roles.create_user(config.remote_location_manager_user, config.remote_location_manager_pass)
Omega::Roles.create_user_role(rlm, :remote_location_manager)

amqp_node  = RJR::AMQPNode.new   :node_id => config.node_id, :broker => config.amqp_broker

amqp_node.listen

sleep 5

local_node = RJR::LocalNode.new  :node_id => config.node_id
session = local_node.invoke_request('users::login', rlm)
local_node.message_headers['session_id'] = session.id

loc3 = Motel::Location.new :id => 3, :movement_strategy => Motel::MovementStrategies::Stopped.instance,
                           :parent_id => 2, :remote_queue => 'motel-rrjr-test-queue'
local_node.invoke_request('motel::create_location', loc3)

Signal.trap("USR1") {
  amqp_node.stop
}

amqp_node.join
