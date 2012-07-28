# remote location manager tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/local_node'
require 'rjr/amqp_node'

describe Motel::RemoteLocationManager do

  before(:all) do
    config = Omega::Config.load :amqp_broker => 'localhost'
    config.node_id = 'motel-rlm-test'

    Motel::RemoteLocationManager.user      = config.remote_location_manager_user
    Motel::RemoteLocationManager.password  = config.remote_location_manager_pass

    Motel::RJRAdapter.init
    Users::RJRAdapter.init

    user = Users::User.new :id => config.remote_location_manager_user, :password => config.remote_location_manager_pass
    @local_node = RJR::LocalNode.new :node_id => config.node_id
    @local_node.invoke_request('users::create_entity', user)
    @local_node.invoke_request('users::add_privilege', user.id, 'create',   'locations')
    @local_node.invoke_request('users::add_privilege', user.id, 'modify',   'locations')

    @amqp_node = RJR::AMQPNode.new :broker => config.amqp_broker, :node_id => config.node_id
    @server_thread = Thread.new {
      @amqp_node.listen
    }
    sleep 1
  end

  after(:all) do
    Motel::Runner.instance.stop
    @amqp_node.stop
    @amqp_node.join
    @server_thread.join
  end

  before(:each) do
    Motel::Runner.instance.clear
  end

  it "should encapsulate one amqp node per remote queue" do
    rlm = Motel::RemoteLocationManager.new
    q1 = rlm.remote_node_for 'motel-rlm-test-queue'
    q2 = rlm.remote_node_for 'motel-rlm-test-queue'
    #q3 = rlm.remote_node_for 'foobar'
    q1.should == q2
    #q1.should_not == q3
  end

  it "should provide access to get remote locations" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_view => false
    Motel::Runner.instance.run loc1

    rlm = Motel::RemoteLocationManager.new
    rloc = rlm.get_location(Motel::Location.new(:id => 42, :remote_queue => 'motel-rlm-test-queue'))
    rloc.id.should == loc1.id
    rloc.to_s.should == loc1.to_s
    rloc.should_not == loc1
  end

  it "should provide access to create remote locations" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :remote_queue => 'motel-rlm-test-queue'

    rlm = Motel::RemoteLocationManager.new
    rlm.create_location(loc1)
    Motel::Runner.instance.locations.size.should == 1
    Motel::Runner.instance.locations.first.id.should == loc1.id
    Motel::Runner.instance.locations.first.should_not == loc1
  end

  it "should provide access to modify remote locations" do
    loc1 = Motel::Location.new :id => 42, :x => 20, :movement_strategy => TestMovementStrategy.new,
                               :remote_queue => 'motel-rlm-test-queue'

    rlm = Motel::RemoteLocationManager.new
    rlm.create_location(loc1)
    Motel::Runner.instance.locations.size.should == 1
    Motel::Runner.instance.locations.first.x.should == 20

    loc1.x = 50
    rlm.update_location(loc1)
    Motel::Runner.instance.locations.size.should == 1
    Motel::Runner.instance.locations.first.x.should == 50
  end
end
