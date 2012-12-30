# client mixin modules tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Client::RemotelyTrackable do
  before(:each) do
    @ship1 = FactoryGirl.build(:ship1)
    FactoryGirl.build(:ship2)
    FactoryGirl.build(:ship3)
    FactoryGirl.build(:ship4)
    FactoryGirl.build(:ship5)

    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
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

    orig = @ship1.location.x
    @ship1.location.x = 5000
    ts = TestShip.get(@ship1.id)
    ts.location.x.should == orig
  end

  it "should allow event handlers to be registered" do
    invoked = 0
    ts = TestShip.get(@ship1.id)
    ts.handle_event(:updated, :foobar) {
      invoked += 1
    }

    Omega::Client::Node.raise_event(:updated, @ship1)
    sleep 0.1
    invoked.should == 1
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
    ships.size.should == 8
    ships.first.id.should == @ship1.id
  end

  it "should retrieve server entity specified by id" do
    ship = TestShip.get(@ship1.id)
    ship.should_not be_nil
    ship.id.should == @ship1.id
  end

  it "should retrieve server entities owned by user" do
    user1 = FactoryGirl.build(:user1)

    ships = TestShip.owned_by(user1.id)
    ships.size.should == 4
    ships.first.id.should == @ship1.id
  end
  
end

describe Omega::Client::TrackState do
  before(:each) do
    @ship1 = FactoryGirl.build(:ship1)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
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
    sleep 0.1
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
    sleep 0.1

    te.instance_variable_get(:@toggled).should be_true
    te.instance_variable_get(:@current_states).should include(:test_state)
    te.instance_variable_get(:@on_toggles_called).should be_true
    te.instance_variable_get(:@off_toggles_called).should be_false
    on_called.should be_true
    off_called.should be_false

    Omega::Client::Node.raise_event(:updated, te)
    sleep 0.1
    te.instance_variable_get(:@toggled).should be_false
    te.instance_variable_get(:@current_states).should_not include(:test_state)
    te.instance_variable_get(:@off_toggles_called).should be_true
    off_called.should be_true
  end
end

describe Omega::Client::HasLocation do
  it "should allow client to track entity movement" do
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_LOCATIONS)

    @ship1 = FactoryGirl.build(:ship1)

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
  before(:each) do
    @ship1 = FactoryGirl.build(:ship1)
    @ship2 = FactoryGirl.build(:ship2)
    @ship3 = FactoryGirl.build(:ship3)

    @stat1 = FactoryGirl.build(:station1)
    @stat2 = FactoryGirl.build(:station2)
    @stat3 = FactoryGirl.build(:station3)
    @stat4 = FactoryGirl.build(:station4)
    @stat5 = FactoryGirl.build(:station5)

    Omega::Client::Node.set(@stat1)
    Omega::Client::Node.set(@stat2)
    Omega::Client::Node.set(@stat3)
    Omega::Client::Node.set(@stat4)
    Omega::Client::Node.set(@stat5)

    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)
  end

  it "should return closest station to entity" do
    ts = TestShip.get(@ship2.id)
    st = ts.closest(:station)
    st.size.should == 4
    st.first.id.should == @stat3.id

    st = ts.closest(:station, :user_owned => true)
    st.size.should == 2
    st.first.id.should == @stat3.id
  end

  it "should return closest resource to entity" do
    ts = TestShip.get(@ship2.id)
    rs = ts.closest(:resource)
    rs.size.should == 2
    rs.first.name.should == 'ast2'
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
    sys2 = FactoryGirl.build(:sys2)
    jg   = FactoryGirl.build(:jump_gate1)

    ts = TestShip.get(@ship3.id)
    ts.jump_to 'sys2'
    ts = TestShip.get(@ship3.id)
    ts.location.parent_id.should == sys2.location.id
    ts.system_name.should == sys2.name
  end
end

describe Omega::Client::InteractsWithEnvironment do
  before(:each) do
    @ship2 = FactoryGirl.build(:ship2)
    @ship4 = FactoryGirl.build(:ship4)
    @ship5 = FactoryGirl.build(:ship5)

    @stat1 = FactoryGirl.build(:station1)
    @stat3 = FactoryGirl.build(:station3)

    @ast1 = FactoryGirl.build(:asteroid1)
    @rs1  = Cosmos::Registry.instance.set_resource(@ast1.name,
                  Cosmos::Resource.new(:name => 'steel', :type => 'metal'), 500)

    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_CREATE,
                           Omega::Roles::ENTITIES_MANUFACTURED)
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
    test_user = FactoryGirl.build(:test_user)

    ts = TestStation.get(@stat3.id)
    ts.construct('Manufactured::Ship',
                   'class' => 'Manufactured::Ship',
                   'type'  => :mining,
                   'id'   => "test-mining-ship")
    ts = TestShip.get('test-mining-ship')
    ts.should_not be_nil
  end
end
