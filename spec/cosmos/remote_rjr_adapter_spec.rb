# additional tests ontop of rjr_adapter verifying remote entity
#   retrieval and management capabilities
#
# makes use of remote_server 
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/local_node'
require 'rjr/amqp_node'

describe Cosmos::RJRAdapter do

  before(:all) do
    config = Omega::Config.load :amqp_broker => 'localhost'
    config.node_id = 'cosmos-rrjr-test'
    Cosmos::RemoteCosmosManager.user      = config.remote_cosmos_manager_user
    Cosmos::RemoteCosmosManager.password  = config.remote_cosmos_manager_pass

    Users::RJRAdapter.init
    Motel::RJRAdapter.init
    Cosmos::RJRAdapter.init
    Cosmos::Registry.instance.init

    @local_node = RJR::LocalNode.new  :node_id => config.node_id
    rcm = Users::User.new :id => config.remote_cosmos_manager_user, :password => config.remote_cosmos_manager_pass
    rcmr = Users::Role.new :id => 'remote_cosmos_manager',
                           :privileges =>
                             Omega::Roles::ROLES[:remote_cosmos_manager].collect { |pe|
                               Users::Privilege.new(:id => pe[0], :entity_id => pe[1])
                             }
    @local_node.invoke_request('users::create_entity', rcm)
    @local_node.invoke_request('users::create_entity', rcmr)
    @local_node.invoke_request('users::add_role', rcm.id, 'remote_cosmos_manager')

    @amqp_node = RJR::AMQPNode.new :broker => config.amqp_broker, :node_id => config.node_id
    @server_thread = Thread.new {
      @amqp_node.listen
    }

    @remote_server_pid = fork{
      Dir.chdir(File.expand_path(File.dirname(__FILE__) + "/../../"))
      exec "spec/remote_cosmos_server.rb"
    }
    sleep 3

    gal1 = Cosmos::Galaxy.new :name => 'gal1', :remote_queue => 'remote_server-queue', :location => Motel::Location.new(:id => 'g1')
    pl1  = Cosmos::Planet.new :name => 'pl1', :location => Motel::Location.new(:id => 'p1')
    TestUser.create.clear_privileges.add_omega_role(:superadmin).login(@local_node)
    @local_node.invoke_request('cosmos::create_entity', gal1, :universe)
    sleep 3
    @local_node.invoke_request('cosmos::create_entity', pl1, 'sys2')

    #sleep 1 # XXX hack y do we need this?
    session = @amqp_node.invoke_request('remote_server-queue', 'users::login', rcm)
    @amqp_node.message_headers['session_id'] = session.id
  end

  after(:all) do
    Motel::Runner.instance.stop
    Motel::Runner.instance.clear
    Cosmos::Registry.instance.init
    @amqp_node.halt
    @amqp_node.join
    @server_thread.join
    Process.kill 'USR1', @remote_server_pid
  end

  it "should get remotely tracked entities" do
    gal1 = @local_node.invoke_request('cosmos::get_entity', 'of_type', :galaxy, 'with_name', 'gal1')
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
    rgal = @amqp_node.invoke_request('remote_server-queue', 'cosmos::get_entity', 'of_type', 'galaxy', 'with_name', 'gal3')
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
