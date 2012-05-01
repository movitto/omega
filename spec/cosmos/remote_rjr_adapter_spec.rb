# additional tests ontop of rjr_adapter verifying remote entity
#   retrieval and management capabilities
#
# makes use of remote_server 
#
# Copyright (C) 2012 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'
require 'rjr/local_node'
require 'rjr/amqp_node'

describe Cosmos::RJRAdapter do

  before(:all) do
    Users::RJRAdapter.init
    Motel::RJRAdapter.init
    Cosmos::RJRAdapter.init

    rcm  = Omega::Roles.create_user('rcm', 'mcr')
    Omega::Roles.create_user_role(rcm, :remote_cosmos_manager)

    @amqp_node = RJR::AMQPNode.new :broker => 'localhost', :node_id => 'cosmos-rrjr-test'
    @server_thread = Thread.new {
      @amqp_node.listen
    }

    @remote_server_pid = fork{
      exec File.expand_path(File.dirname(__FILE__) + "/../remote_cosmos_server.rb")
    }
    sleep 1

    gal1 = Cosmos::Galaxy.new :name => 'gal1', :remote_queue => 'remote_server-queue'
    pl1  = Cosmos::Planet.new :name => 'pl1'
    @local_node = RJR::LocalNode.new  :node_id => 'cosmos-rrjr-test'
    TestUser.create.clear_privileges.add_role(:superadmin).login(@local_node)
    @local_node.invoke_request('cosmos::create_entity', gal1, :universe)
    sleep 3
    @local_node.invoke_request('cosmos::create_entity', pl1, 'sys2')

    #sleep 1 # XXX hack y do we need this?
    session = @amqp_node.invoke_request('remote_server-queue', 'users::login', rcm)
    @amqp_node.message_headers['session_id'] = session.id
  end

  after(:all) do
    Motel::Runner.instance.stop
    @amqp_node.stop
    @amqp_node.join
    @server_thread.join
    Process.kill 'INT', @remote_server_pid
  end

  it "should get remotely tracked entities" do
    gal1 = @local_node.invoke_request('cosmos::get_entity', :galaxy, 'gal1')
    gal1.name.should == 'gal1'
    gal1.solar_systems.size.should == 2
    gal1.solar_systems.first.name.should == 'sys1'
    gal1.solar_systems.last.name.should == 'sys2'
    gal1.solar_systems.last.planets.size.should == 1
    gal1.solar_systems.last.planets.first.name.should == 'pl1'
  end

  it "should create remotely tracked entities" do
    gal3 = Cosmos::Galaxy.new :name => 'gal3', :remote_queue => 'remote_server-queue'
    @local_node.invoke_request('cosmos::create_entity', gal3, :universe)
    rgal = @amqp_node.invoke_request('remote_server-queue', 'cosmos::get_entity', 'galaxy', 'gal3')
    rgal.class.should == Cosmos::Galaxy
    rgal.name.should == 'gal3'
  end

  it "should create placeholder parent when creating remotely tracked entities" do
    sys3 = Cosmos::SolarSystem.new :name => 'sys3'
    @local_node.invoke_request('cosmos::create_entity', sys3, 'gal2')
    pgal = Cosmos::Registry.instance.find_entity :type => :galaxy, :name => 'gal2'
    pgal.class.should == Cosmos::Galaxy
    pgal.name.should == 'gal2'
    pgal.remote_queue.should == ''
  end
end
