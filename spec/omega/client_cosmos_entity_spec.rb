# client cosmos_entity module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Client::Galaxy do
  before(:all) do
    Motel::RJRAdapter.init
    Users::RJRAdapter.init
    Cosmos::RJRAdapter.init
    Manufactured::RJRAdapter.init

    TestUser.create.clear_privileges.add_omega_role(:superadmin)

    Omega::Client::Node.client_username = TestUser.id
    Omega::Client::Node.client_password = TestUser.password

    @local_node = RJR::LocalNode.new :node_id => 'omega-test'
    Omega::Client::Node.node = @local_node
  end

  before(:each) do
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    Cosmos::Registry.instance.add_child gal1
    Motel::Runner.instance.run gal1.location
  end

  after(:all) do
    Motel::Runner.instance.stop
  end

  it "should be remotely trackable" do
    g = Omega::Client::Galaxy.get('gal1')
    g.id.should == 'gal1'
  end
end

describe Omega::Client::SolarSystem do
  before(:all) do
    Motel::RJRAdapter.init
    Users::RJRAdapter.init
    Cosmos::RJRAdapter.init
    Manufactured::RJRAdapter.init

    TestUser.create.clear_privileges.add_omega_role(:superadmin)

    Omega::Client::Node.client_username = TestUser.id
    Omega::Client::Node.client_password = TestUser.password

    @local_node = RJR::LocalNode.new :node_id => 'omega-test'
    Omega::Client::Node.node = @local_node

    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    sys2  = Cosmos::SolarSystem.new :name => 'sys2', :location => Motel::Location.new(:id => '202')
    sys3  = Cosmos::SolarSystem.new :name => 'sys3', :location => Motel::Location.new(:id => '203')
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => TestUser.id, :location => Motel::Location.new(:id => '105', :x => -100, :y => -100, :z => -100)
    stat2 = Manufactured::Station.new :id => 'station2', :user_id => TestUser.id, :location => Motel::Location.new(:id => '106', :x => 150,  :y => 150,  :z => 150)
    stat3 = Manufactured::Station.new :id => 'station3', :user_id => TestUser.id, :type => :manufacturing, :location => Motel::Location.new(:id => '107', :x => 100,  :y => 100,  :z => 100), :resources => { 'metal-rock' => 300 }

    gal1.add_child(sys1)
    gal1.add_child(sys2)
    gal1.add_child(sys3)
    stat1.parent = sys1
    stat2.parent = stat3.parent = sys2
    Cosmos::Registry.instance.add_child gal1
    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run sys2.location
    Motel::Runner.instance.run sys3.location
    Motel::Runner.instance.run stat1.location
    Motel::Runner.instance.run stat2.location
    Motel::Runner.instance.run stat3.location
    Manufactured::Registry.instance.create stat1
    Manufactured::Registry.instance.create stat2
    Manufactured::Registry.instance.create stat3
  end

  it "should be remotely trackable" do
    s = Omega::Client::SolarSystem.get('sys1')
    s.id.should == 'sys1'
  end

  it "should return system with the fewest stations" do
    sys = Omega::Client::SolarSystem.with_fewest "Manufactured::Station"
    sys.should_not be_nil
    sys.id.should == 'sys2'
  end
end
