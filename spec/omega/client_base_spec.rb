# client base module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

# TODO test and optimize/consolidate all client & bot subsystems

describe Omega::Client::Entity do

  before(:all) do
    Motel::RJRAdapter.init
    Users::RJRAdapter.init
    Cosmos::RJRAdapter.init
    Manufactured::RJRAdapter.init

    @local_node = RJR::LocalNode.new :node_id => 'omega-test'
    Omega::Client::Tracker.node = @local_node
    TestUser.create.login(@local_node).clear_privileges.add_omega_role(:superadmin)
  end

  before(:each) do
    Motel::Runner.instance.clear
    Cosmos::Registry.instance.init
    Manufactured::Registry.instance.init
    Omega::Client::Tracker.instance.clear

    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    @ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')
    @ship2 = Manufactured::Ship.new :id => 'ship2', :user_id => 'user1', :location => Motel::Location.new(:id => '102')
    @stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '101')
    @user1 = Users::User.new :id => 'user1'

    gal1.add_child(sys1) ;
    @ship1.parent = @ship2.parent = @stat1.parent = sys1
    Users::Registry.instance.create @user1
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @ship2.location
    Motel::Runner.instance.run @stat1.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @ship2
    Manufactured::Registry.instance.create @stat1
  end

  after(:all) do
    Motel::Runner.instance.stop
  end

  it "should retrieve all server entities" do
    ships = TestClientShip.get_all
    ships.size.should == 2
    ships.first.id.should == @ship1.id
    ships.last.id.should  == @ship2.id
    Omega::Client::Tracker['Manufactured::Ship-ship1'].id.should == @ship1.id
    Omega::Client::Tracker['Manufactured::Ship-ship2'].id.should == @ship2.id
  end

  # it should validate / filter all entities retrieved

  it "should retrieve server entity specified by id" do
    cship = TestClientShip.get('ship1')
    cship.id.should == @ship1.id
    Omega::Client::Tracker['Manufactured::Ship-ship1'].id.should == @ship1.id
  end

  it "should retrieve server entities owned by user" do
    entities = TestClientShip.owned_by('user1')
    entities.size.should == 2
    entities.first.id.should == @ship1.id
    entities.last.id.should  == @ship2.id
    Omega::Client::Tracker['Manufactured::Ship-ship1'].id.should == @ship1.id
    Omega::Client::Tracker['Manufactured::Ship-ship2'].id.should == @ship2.id
  end

  # it should validate / filter all entities owned by user

  it "should retrieve tracked entity on demand" do
    ship = TestClientShip.get('ship1')
    Omega::Client::Tracker['Manufactured::Ship-ship1'].id.should == @ship1.id

    @ship1.size = 500
    ship.get
    ship.size.should == 500
    Omega::Client::Tracker['Manufactured::Ship-ship1'].size.should == 500
  end

  # TODO test events / event cycle

end

describe Omega::Client::Tracker do

  before(:each) do
    Omega::Client::Tracker.instance.clear
  end

  # it should listen to requests on the specified node ?
  # it should allow requests to be invoked over internal node ?

  it "it should provide a protection mechanism to modify tracked entities" do
    Omega::Client::Tracker.instance.synchronize {
      lambda {
        Omega::Client::Tracker.instance.synchronize {}
      }.should raise_error(ThreadError)
    }
  end

  it "it should allow tracked entities to be added and retrieved" do
    loc1 = Motel::Location.new :id => 42
    Omega::Client::Tracker[42] = loc1
    Omega::Client::Tracker[42].should == loc1
  end

end
