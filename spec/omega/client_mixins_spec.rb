# client mixin modules tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Client::RemotelyTrackable do
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
    Motel::Runner.instance.clear
    Cosmos::Registry.instance.init
    Manufactured::Registry.instance.init

    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    sys2  = Cosmos::SolarSystem.new :name => 'sys2', :location => Motel::Location.new(:id => '202')
    ast1  = Cosmos::Asteroid.new :name => 'ast1', :location => Motel::Location.new(:id => 203, :x => -200, :y => -200, :z => -200)
    ast2  = Cosmos::Asteroid.new :name => 'ast2', :location => Motel::Location.new(:id => 204, :x =>  200, :y =>  200, :z =>  200)
    jg1   = Cosmos::JumpGate.new :solar_system => sys1,  :endpoint => sys2, :location => Motel::Location.new(:id => 205, :x =>  150, :y =>  150, :z =>  150)
    @ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')
    @ship2 = Manufactured::Ship.new :id => 'ship2', :user_id => 'user2', :type => :mining, :location => Motel::Location.new(:id => '102', :x => 100, :y => 100, :z => 100), :resources => { 'metal-alluminum' => 50 }
    @ship3 = Manufactured::Ship.new :id => 'ship3', :user_id => 'user1', :location => Motel::Location.new(:id => '103', :x => 150, :y => 150, :z => 150)
    @ship4 = Manufactured::Ship.new :id => 'ship4', :user_id => 'user1', :type => :corvette, :location => Motel::Location.new(:id => '104', :x => 90, :y => 90, :z => 90)
    @ship5 = Manufactured::Ship.new :id => 'ship5', :user_id => 'user2', :type => :corvette, :location => Motel::Location.new(:id => '105', :x => 80, :y => 80, :z => 80)
    @stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '106', :x => -100, :y => -100, :z => -100)
    @stat2 = Manufactured::Station.new :id => 'station2', :user_id => 'user1', :location => Motel::Location.new(:id => '107', :x => 150,  :y => 150,  :z => 150)
    @stat3 = Manufactured::Station.new :id => 'station3', :user_id => 'user2', :type => :manufacturing, :location => Motel::Location.new(:id => '108', :x => 100,  :y => 100,  :z => 100), :resources => { 'metal-rock' => 300 }
    @user1 = Users::User.new :id => 'user1'
    @user2 = Users::User.new :id => 'user2'

    gal1.add_child(sys1) ; gal1.add_child(sys2)
    sys1.add_child(ast1) ; sys1.add_child(ast2) ; sys1.add_child(jg1)
    @ship1.parent = @ship2.parent =
    @ship3.parent = @ship4.parent = @ship5.parent =
    @stat1.parent = @stat2.parent = @stat3.parent = sys1
    Users::Registry.instance.create @user1
    Users::Registry.instance.create @user2
    Cosmos::Registry.instance.add_child gal1
    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run sys2.location
    Motel::Runner.instance.run ast1.location
    Motel::Runner.instance.run ast2.location
    Motel::Runner.instance.run jg1.location
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @ship2.location
    Motel::Runner.instance.run @ship3.location
    Motel::Runner.instance.run @ship4.location
    Motel::Runner.instance.run @ship5.location
    Motel::Runner.instance.run @stat1.location
    Motel::Runner.instance.run @stat2.location
    Motel::Runner.instance.run @stat3.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @ship2
    Manufactured::Registry.instance.create @ship3
    Manufactured::Registry.instance.create @ship4
    Manufactured::Registry.instance.create @ship5
    Manufactured::Registry.instance.create @stat1
    Manufactured::Registry.instance.create @stat2
    Manufactured::Registry.instance.create @stat3

    @rs1 = Cosmos::Registry.instance.set_resource(ast1.name,
                 Cosmos::Resource.new(:name => 'steel', :type => 'metal'), 500)
  end

  after(:all) do
    Motel::Runner.instance.clear
  end

  it "should return tracked entity" do
    ts = TestShip.get(@ship1.id)
    ts.entity.should == Omega::Client::Node.get(@ship1.id)
  end

  it "should dispatch methods to tracked entity" do
    ts = TestShip.get(@ship1.id)
    ts.type.should == @ship1.type
    ts.location.should == ts.entity.location
  end

  it "should retrieved tracked entity from the server" do
    ts = TestShip.get(@ship1.id)
    ts.location.x.should == @ship1.location.x

    @ship1.location.x = 5000
    ts = TestShip.get(@ship1.id)
    ts.location.x.should == @ship1.location.x
  end

  it "should allow event handlers to be registered" do
    invoked = 0
    ts = TestShip.get(@ship1.id)
    ts.handle_event(:updated, :foobar) {
      invoked += 1
    }

    ts = TestShip.get(@ship1.id)
    sleep(Omega::Client::Node.refresh_time + 0.1)
    invoked.should > 1
  end

  it "should invoke event setup methods when registering an event handler" do
    ts = TestShip.get(@ship1.id)
    ts.handle_event(:test, :foobar)
    ts.instance_variable_get(:@test_setup_args).should include(:foobar)
    ts.instance_variable_get(:@test_setup_invoked).should be_true
  end

  it "should allow client to set/get entity_type to track" do
    old = TestEntity.entity_type
    TestEntity.entity_type(:foobar)
    TestEntity.entity_type.should == :foobar
    TestEntity.entity_type(old)
  end

  it "should allow client to specify additional entity validation method" do
    invoked = 0
    TestShip.entity_validation { |e|
      invoked += 1
      true
    }
    ts = TestShip.get(@ship1.id)
    ts.should_not be_nil
    invoked.should == 1

    TestShip.entity_validation { |e|
      invoked += 1
      false
    }
    ts = TestShip.get(@ship1.id)
    ts.should be_nil
    invoked.should == 2

    TestShip.entity_validation { |e| true }
  end

  it "should allow client to specify additional entity init method" do
    invoked = 0
    TestShip.on_init { |e|
      invoked += 1
    }
    ts = TestShip.get(@ship1.id)
    ts.should_not be_nil
    invoked.should == 1
  end

  it "should allow client to specify method to retrieve entity from server" do
    old = TestEntity.get_method
    TestEntity.get_method(:foobar)
    TestEntity.get_method.should == :foobar
    TestEntity.get_method(old)
  end

  it "should allow client to register entity events" do
    invoked = 0
    TestEntity.server_event :foobar => 
                                  { :setup => 
                                      lambda { |a|
                                        a.should == :barfoo
                                        invoked += 1
                                      }
                                   }
    te = TestEntity.new
    te.handle_event(:foobar, :barfoo)
    invoked.should == 1
    # TODO also test subscribe and notification
  end

  it "should retrieve all server entities" do
    ships = TestShip.get_all
    ships.size.should == 5
    ships.first.id.should == @ship1.id
  end

  it "should retrieve server entity specified by id" do
    ship = TestShip.get(@ship1.id)
    ship.should_not be_nil
    ship.id.should == @ship1.id
  end

  it "should retrieve server entities owned by user" do
    ships = TestShip.owned_by('user1')
    ships.size.should == 3
    ships.first.id.should == @ship1.id
  end
  
end

describe Omega::Client::TrackState do
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
    Motel::Runner.instance.clear
    Cosmos::Registry.instance.init
    Manufactured::Registry.instance.init

    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    @ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')

    gal1.add_child(sys1)
    @ship1.parent = sys1
    Users::Registry.instance.create @user1
    Cosmos::Registry.instance.add_child gal1
    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run @ship1.location
    Manufactured::Registry.instance.create @ship1
  end

  after(:all) do
    Motel::Runner.instance.clear
  end

  it "should allow client to register entity states" do
    toggle = true
    TestShip.server_state :foobar,
                                  { :check => 
                                      lambda { |a|
                                        toggle = !toggle
                                      }
                                   }
    te = TestShip.get(@ship1.id)
    # TODO should check immediately on creation
    toggle.should.should be_true
    Omega::Client::Node.raise_event(:updated, te)
    sleep(Omega::Client::Node.refresh_time + 0.1)
    toggle.should be_false
  end

  it "should invoke on/off state handlers" do
    on_called  = false
    off_called = false
    te = TestEntity.get(@ship1.id)
    te.on_state(:test_state)  { |e|
      on_called = true
    }
    te.off_state(:test_state) { |e|
      off_called = true
    }

    # see todo in previous test
    Omega::Client::Node.raise_event(:updated, te)
    sleep(Omega::Client::Node.refresh_time + 0.1)

    te.instance_variable_get(:@toggled).should be_true
    te.instance_variable_get(:@current_states).should include(:test_state)
    te.instance_variable_get(:@on_toggles_called).should be_true
    te.instance_variable_get(:@off_toggles_called).should be_false
    on_called.should be_true
    off_called.should be_false

    Omega::Client::Node.raise_event(:updated, te)
    sleep(Omega::Client::Node.refresh_time + 0.1)
    te.instance_variable_get(:@toggled).should be_false
    te.instance_variable_get(:@current_states).should_not include(:test_state)
    te.instance_variable_get(:@off_toggles_called).should be_true
    off_called.should be_true
  end
end

describe Omega::Client::HasLocation do
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
    Motel::Runner.instance.clear
    Cosmos::Registry.instance.init
    Manufactured::Registry.instance.init

    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    @ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')

    gal1.add_child(sys1)
    @ship1.parent = sys1
    Users::Registry.instance.create @user1
    Cosmos::Registry.instance.add_child gal1
    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run @ship1.location
    Manufactured::Registry.instance.create @ship1
  end

  after(:all) do
    Motel::Runner.instance.clear
  end

  it "should allow client to track entity movement" do
    ts = TestShip.get(@ship1.id)
    nloc = ts.location + [50,50,50]
    Omega::Client::Node.invoke_request 'manufactured::move_entity', @ship1.id, nloc
    invoked = 0 ; slid = @ship1.location.id
    ts.handle_event(:movement, 5) { |e|
      e.id.should == slid
      invoked += 1
    }
    sleep 3
    invoked.should > 0
    Omega::Client::Node.invoke_request 'manufactured::stop_entity', @ship1.id
  end
end

describe Omega::Client::InSystem do
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
    Motel::Runner.instance.clear
    Cosmos::Registry.instance.init
    Manufactured::Registry.instance.init

    @gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    @sys1  = Cosmos::SolarSystem.new :name => 'sys11', :location => Motel::Location.new(:id => '201')
    @sys2  = Cosmos::SolarSystem.new :name => 'sys21', :location => Motel::Location.new(:id => '202')
    @ast1  = Cosmos::Asteroid.new :name => 'ast1', :location => Motel::Location.new(:id => 203, :x => -200, :y => -200, :z => -200)
    @ast2  = Cosmos::Asteroid.new :name => 'ast2', :location => Motel::Location.new(:id => 204, :x =>  200, :y =>  200, :z =>  200)
    @jg1   = Cosmos::JumpGate.new :solar_system => @sys1,  :endpoint => @sys2, :location => Motel::Location.new(:id => 205, :x =>  150, :y =>  150, :z =>  150)
    @ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')
    @ship2 = Manufactured::Ship.new :id => 'ship2', :user_id => 'user2', :type => :mining, :location => Motel::Location.new(:id => '102', :x => 100, :y => 100, :z => 100), :resources => { 'metal-alluminum' => 50 }
    @ship3 = Manufactured::Ship.new :id => 'ship3', :user_id => 'user1', :location => Motel::Location.new(:id => '103', :x => 150, :y => 150, :z => 150)
    @ship4 = Manufactured::Ship.new :id => 'ship4', :user_id => 'user1', :type => :corvette, :location => Motel::Location.new(:id => '104', :x => 90, :y => 90, :z => 90)
    @ship5 = Manufactured::Ship.new :id => 'ship5', :user_id => 'user2', :type => :corvette, :location => Motel::Location.new(:id => '105', :x => 80, :y => 80, :z => 80)
    @stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '106', :x => -100, :y => -100, :z => -100)
    @stat2 = Manufactured::Station.new :id => 'station2', :user_id => 'user1', :location => Motel::Location.new(:id => '107', :x => 150,  :y => 150,  :z => 150)
    @stat3 = Manufactured::Station.new :id => 'station3', :user_id => 'omega-test', :type => :manufacturing, :location => Motel::Location.new(:id => '108', :x => 100,  :y => 100,  :z => 100), :resources => { 'metal-rock' => 300 }
    @user1 = Users::User.new :id => 'user1'
    @user2 = Users::User.new :id => 'user2'

    @gal1.add_child(@sys1) ; @gal1.add_child(@sys2)
    @sys1.add_child(@ast1) ; @sys1.add_child(@ast2)
    @sys1.add_child(@jg1)
    @ship1.parent = @ship2.parent =
    @ship3.parent = @ship4.parent = @ship5.parent =
    @stat1.parent = @stat2.parent = @stat3.parent = @sys1
    Users::Registry.instance.create @user1
    Users::Registry.instance.create @user2
    Cosmos::Registry.instance.add_child @gal1
    Motel::Runner.instance.run @gal1.location
    Motel::Runner.instance.run @sys1.location
    Motel::Runner.instance.run @sys2.location
    Motel::Runner.instance.run @ast1.location
    Motel::Runner.instance.run @ast2.location
    Motel::Runner.instance.run @jg1.location
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @ship2.location
    Motel::Runner.instance.run @ship3.location
    Motel::Runner.instance.run @ship4.location
    Motel::Runner.instance.run @ship5.location
    Motel::Runner.instance.run @stat1.location
    Motel::Runner.instance.run @stat2.location
    Motel::Runner.instance.run @stat3.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @ship2
    Manufactured::Registry.instance.create @ship3
    Manufactured::Registry.instance.create @ship4
    Manufactured::Registry.instance.create @ship5
    Manufactured::Registry.instance.create @stat1
    Manufactured::Registry.instance.create @stat2
    Manufactured::Registry.instance.create @stat3

    @rs1 = Cosmos::Registry.instance.set_resource(@ast1.name,
                 Cosmos::Resource.new(:name => 'steel', :type => 'metal'), 500)

    Omega::Client::Node.set(@stat1)
    Omega::Client::Node.set(@stat2)
    Omega::Client::Node.set(@stat3)
  end

  after(:all) do
    Motel::Runner.instance.clear
  end

  it "should return closest station to entity" do
    ts = TestShip.get(@ship2.id)
    st = ts.closest(:station)
    st.size.should == 3
    st.first.id.should == @stat3.id

    st = ts.closest(:station, :user_owned => true)
    st.size.should == 1
    st.first.id.should == @stat3.id
  end

  it "should return closest resource to entity" do
    ts = TestShip.get(@ship2.id)
    rs = ts.closest(:resource)
    rs.size.should == 1
    rs.first.name.should == @ast1.name
  end

  it "should move entity in system, invoking callback on arrival" do
    cv = ConditionVariable.new
    cm = Mutex.new

    ts = TestShip.get(@ship1.id)
    nx = ts.location.x + 50
    ts.move_to :location => Motel::Location.new(:x => nx, :y => ts.location.y, :z => ts.location.z) { |e|
      e.id.should == @ship1.id
      e.location.x.should == nx
      cm.synchronize { cv.wait cm }
    }
    cm.synchronize { cv.signal }
  end

  it "should stop moving entity" do
    ts = TestShip.get(@ship1.id)
    nx = ts.location.x + 50
    ts.move_to :location => Motel::Location.new(:x => nx, :y => ts.location.y, :z => ts.location.z)
    ts.stop_moving
    ts = TestShip.get(@ship1.id)
    ts.location.movement_strategy.class.should == Motel::MovementStrategies::Stopped
  end

  it "jump entity to system" do
    ts = TestShip.get(@ship3.id)
    ts.jump_to 'sys2'
    ts = TestShip.get(@ship3.id)
    ts.location.parent_id.should == @sys2.location.id
    ts.system_name.should == @sys2.name
  end
end

describe Omega::Client::InteractsWithEnvironment do
  before(:all) do
    Motel::RJRAdapter.init
    Users::RJRAdapter.init
    Cosmos::RJRAdapter.init
    Manufactured::RJRAdapter.init

    TestUser.create.clear_privileges.create_user_role.add_omega_role(:superadmin)

    Omega::Client::Node.client_username = TestUser.id
    Omega::Client::Node.client_password = TestUser.password

    @local_node = RJR::LocalNode.new :node_id => 'omega-test'
    Omega::Client::Node.node = @local_node
  end

  before(:each) do
    Motel::Runner.instance.clear
    Cosmos::Registry.instance.init
    Manufactured::Registry.instance.init

    @gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    @sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    @ast1  = Cosmos::Asteroid.new :name => 'ast1', :location => Motel::Location.new(:id => 203, :x => 110, :y => 110, :z => 110)
    @ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')
    @ship2 = Manufactured::Ship.new :id => 'ship2', :user_id => 'user2', :type => :mining, :location => Motel::Location.new(:id => '102', :x => 100, :y => 100, :z => 100), :resources => { 'metal-alluminum' => 50 }
    @ship3 = Manufactured::Ship.new :id => 'ship3', :user_id => 'user1', :location => Motel::Location.new(:id => '103', :x => 150, :y => 150, :z => 150)
    @ship4 = Manufactured::Ship.new :id => 'ship4', :user_id => 'user1', :type => :corvette, :location => Motel::Location.new(:id => '104', :x => 90, :y => 90, :z => 90)
    @ship5 = Manufactured::Ship.new :id => 'ship5', :user_id => 'user2', :type => :corvette, :location => Motel::Location.new(:id => '105', :x => 80, :y => 80, :z => 80)
    @stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '106', :x => -100, :y => -100, :z => -100)
    @stat2 = Manufactured::Station.new :id => 'station2', :user_id => 'user1', :location => Motel::Location.new(:id => '107', :x => 150,  :y => 150,  :z => 150)
    @stat3 = Manufactured::Station.new :id => 'station3', :user_id => 'omega-test', :type => :manufacturing, :location => Motel::Location.new(:id => '108', :x => 100,  :y => 100,  :z => 100), :resources => { 'metal-rock' => 300 }
    @user1 = Users::User.new :id => 'user1'
    @user2 = Users::User.new :id => 'user2'

    @gal1.add_child(@sys1) ; @sys1.add_child(@ast1)
    @ship1.parent = @ship2.parent =
    @ship3.parent = @ship4.parent = @ship5.parent =
    @stat1.parent = @stat2.parent = @stat3.parent = @sys1
    Users::Registry.instance.create @user1
    Users::Registry.instance.create @user2
    Cosmos::Registry.instance.add_child @gal1
    Motel::Runner.instance.run @gal1.location
    Motel::Runner.instance.run @sys1.location
    Motel::Runner.instance.run @ast1.location
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @ship2.location
    Motel::Runner.instance.run @ship3.location
    Motel::Runner.instance.run @ship4.location
    Motel::Runner.instance.run @ship5.location
    Motel::Runner.instance.run @stat1.location
    Motel::Runner.instance.run @stat2.location
    Motel::Runner.instance.run @stat3.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @ship2
    Manufactured::Registry.instance.create @ship3
    Manufactured::Registry.instance.create @ship4
    Manufactured::Registry.instance.create @ship5
    Manufactured::Registry.instance.create @stat1
    Manufactured::Registry.instance.create @stat2
    Manufactured::Registry.instance.create @stat3

    @rs1 = Cosmos::Registry.instance.set_resource(@ast1.name,
                 Cosmos::Resource.new(:name => 'steel', :type => 'metal'), 500)
  end

  after(:all) do
    Motel::Runner.instance.clear
  end


  it "should mine resource using entity" do
    ts = TestShip.get(@ship2.id)
    ts.mine(@rs1)
    sleep 0.5 # XXX need to wait for mining cycle to begin

    ts = TestShip.get(@ship2.id)
    ts.mining.should_not be_nil
    ts.mining.id.should == @rs1.id
  end

  it "should attack target using entity" do
    ts = TestShip.get(@ship4.id)
    ts.attack(@ship5)
    # XXX need better way to verify:
    Manufactured::Registry.instance.attack_commands.size.should == 1
    Manufactured::Registry.instance.attack_commands[@ship4.id].attacker.id.should == @ship4.id
    Manufactured::Registry.instance.attack_commands[@ship4.id].defender.id.should == @ship5.id
  end

  #it "should transfer all entity resources to target" do
    # TODO
  #end

  it "should transfer specified entity resource to target" do
    ts = TestShip.get(@ship2.id)
    ts.transfer(50, :of => 'metal-alluminum', :to => @stat3)
    ts = TestShip.get(@ship2.id)
    ts.resources.find { |i,q| i == 'metal-alluminum' }.should be_nil

    ts = TestStation.get(@stat3.id)
    ts.resources.find { |i,q| i == 'metal-alluminum' }.last.should == 50
  end

  it "should construct entity" do
    ts = TestStation.get(@stat3.id)
    ts.construct('Manufactured::Ship',
                   'class' => 'Manufactured::Ship',
                   'type'  => :mining,
                   'id'   => "test-mining-ship")
    ts = TestShip.get('test-mining-ship')
    ts.should_not be_nil
  end
end
