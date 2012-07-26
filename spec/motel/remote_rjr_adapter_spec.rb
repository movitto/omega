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

describe Motel::RJRAdapter do

  before(:all) do
    config = Omega::Config.load :amqp_broker => 'localhost'
    config.node_id = 'motel-rrjr-test'

    Motel::RemoteLocationManager.user      = config.remote_location_manager_user
    Motel::RemoteLocationManager.password  = config.remote_location_manager_pass

    Users::RJRAdapter.init
    Motel::RJRAdapter.init

    rlm  = Omega::Roles.create_user(config.remote_location_manager_user, config.remote_location_manager_pass)
    Omega::Roles.create_user_role(rlm, :remote_location_manager)

    @amqp_node = RJR::AMQPNode.new :broker => config.amqp_broker, :node_id => config.node_id
    @server_thread = Thread.new {
      @amqp_node.listen
    }

    @remote_server_pid = fork{
      Dir.chdir(File.expand_path(File.dirname(__FILE__) + "/../../"))
      exec "spec/remote_location_server.rb"
    }
    sleep 2

    loc1 = Motel::Location.new :id => 1, :movement_strategy => Motel::MovementStrategies::Stopped.instance
    loc2 = Motel::Location.new :id => 2, :movement_strategy => Motel::MovementStrategies::Stopped.instance,
                               :parent_id => 1, :remote_queue => 'remote_server-queue'
    loc4 = Motel::Location.new :id => 4, :movement_strategy => Motel::MovementStrategies::Stopped.instance,
                               :parent_id => 3
    @local_node = RJR::LocalNode.new  :node_id => config.node_id
    TestUser.create.clear_privileges.add_role(:superadmin).login(@local_node)
    @local_node.invoke_request('motel::create_location', loc1)
    @local_node.invoke_request('motel::create_location', loc2)
    sleep 3
    @local_node.invoke_request('motel::create_location', loc4)
  end

  after(:all) do
    Motel::Runner.instance.stop
    @amqp_node.stop
    @amqp_node.join
    @server_thread.join
    Process.kill 'INT', @remote_server_pid
  end

  it "should get remotely tracked locations" do
    loc1 = @local_node.invoke_request('motel::get_location', 'with_id', 1)
    loc1.id.should == 1
    loc1.children.size.should == 1

    loc2 = loc1.children.first
    loc2.id.should == 2
    loc2.children.size.should == 1

    loc3 = loc2.children.first
    loc3.id.should == 3
    loc3.children.size.should == 1

    loc4 = loc3.children.first
    loc4.id.should == 4
    loc4.children.size.should == 0
  end

  it "should create remotely tracked locations" do
    loc = Motel::Location.new :id => 'create_test', :movement_strategy => Motel::MovementStrategies::Stopped.instance,
                              :remote_queue => 'remote_server-queue', :restrict_view => false
    @local_node.invoke_request('motel::create_location', loc)

    # retrieve location from remote queue
    rloc = @amqp_node.invoke_request('remote_server-queue', 'motel::get_location', 'with_id', 'create_test')
    rloc.class.should == Motel::Location
    rloc.id.should == 'create_test'
  end

  it "should update remotely tracked locations" do
    loc = Motel::Location.new :id => 'update_test', :movement_strategy => Motel::MovementStrategies::Stopped.instance,
                              :remote_queue => 'remote_server-queue', :restrict_view => false
    @local_node.invoke_request('motel::create_location', loc)

    loc.x = 50
    @local_node.invoke_request('motel::update_location', loc)

    # retrieve location from remote queue
    rloc = @amqp_node.invoke_request('remote_server-queue', 'motel::get_location', 'with_id', 'update_test')
    rloc.class.should == Motel::Location
    rloc.id.should == 'update_test'
    rloc.x.should == 50
  end
end
