# client cosmos_entity module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Client::Galaxy do
  it "should be remotely trackable" do
    gal1  = FactoryGirl.build(:gal1)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITY_COSMOS + gal1.id)

    g = Omega::Client::Galaxy.get(gal1.name)
    g.id.should == gal1.name
  end
end

describe Omega::Client::SolarSystem do
  it "should be remotely trackable" do
    sys1  = FactoryGirl.build(:sys1)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITY_COSMOS + sys1.id)

    s = Omega::Client::SolarSystem.get('sys1')
    s.id.should == 'sys1'
  end

  it "should return closest system with no stations" do
    stat1 = FactoryGirl.build(:station1)
    stat2 = FactoryGirl.build(:station2)
    stat3 = FactoryGirl.build(:station3)
    sys1  = FactoryGirl.build(:sys1)

    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)

    csys1 = Omega::Client::SolarSystem.get('sys1')
    neighbor = csys1.closest_neighbor_with_no "Manufactured::Station"
    neighbor.name.should == "sys3"
  end

  it "should return system with the fewest stations" do
    stat1 = FactoryGirl.build(:station1)
    stat2 = FactoryGirl.build(:station2)
    stat3 = FactoryGirl.build(:station3)

    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)

    sys = Omega::Client::SolarSystem.with_fewest "Manufactured::Station"
    sys.should_not be_nil
    sys.id.should == 'sys2'
  end

  it "should cache solar systems" do
    sys1  = FactoryGirl.build(:sys1)
    ssys  = Cosmos::Registry.instance.find_entity(:name => 'sys1')
    ssys.background = 'sys1'

    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITY_COSMOS + sys1.id)

    s = Omega::Client::SolarSystem.cached('sys1')
    s.id.should == 'sys1'
    s.background.should == "sys1"

    ssys.background = 'sys2'
    s = Omega::Client::SolarSystem.cached('sys1')
    s.id.should == 'sys1'
    s.background.should == "sys1"
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

describe Omega::Client::HasCargo do
  before(:each) do
    @ship2 = FactoryGirl.build(:ship2)
    @ship4 = FactoryGirl.build(:ship4)
    @ship5 = FactoryGirl.build(:ship5)

    @stat1 = FactoryGirl.build(:station1)
    @stat3 = FactoryGirl.build(:station3)

    @loot1 = FactoryGirl.build(:loot1)

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

    crse = ts.solar_system.asteroids.find { |a| a.name == @rs1.entity.name }
    crs  = crse.resource_sources.find { |rs| rs.id == @rs1.id }
    oldq = crs.quantity

    ts.mine(@rs1)
    sleep 0.5 # XXX need to wait for mining cycle to begin

    ts = TestShip.get(@ship2.id)
    ts.mining.should_not be_nil
    ts.mining.id.should == @rs1.id

    # ensure resource_collected is being tracked
    ts.has_event_handler?(:resource_collected).should be_true

    # ensure resource sources are invalidated
    crs  = crse.resource_sources.find { |rs| rs.id == @rs1.id }
    crs.quantity.should < oldq
  end

  it "should attack target using entity" do
    ts = TestShip.get(@ship4.id)
    ts.attack(@ship5)
    # XXX need better way to verify:
    Manufactured::Registry.instance.attack_commands.size.should == 1
    Manufactured::Registry.instance.attack_commands[@ship4.id].attacker.id.should == @ship4.id
    Manufactured::Registry.instance.attack_commands[@ship4.id].defender.id.should == @ship5.id
  end

  #it "should dock/undock from station" do
    # TODO
  #end

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

  it "should collect loot" do
    oldr = Hash[@loot1.resources]
    ts = TestShip.get(@ship4.id)
    ts.collect_loot @loot1
    ts = TestShip.get(@ship4.id)
    ts.resources.should == oldr
    @loot1.quantity.should == 0
  end

  it "should construct entity" do
    test_user = FactoryGirl.build(:test_user)

    ts = TestStation.get(@stat3.id)
    ts.construct('Manufactured::Ship',
                   'class' => 'Manufactured::Ship',
                   'type'  => :mining,
                   'id'   => "test-mining-ship")
    sleep(Manufactured::Ship.construction_time(:mining)+1)
    ts = TestShip.get('test-mining-ship')
    ts.should_not be_nil
  end
end
