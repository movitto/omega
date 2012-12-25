# client ship tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

#RJR::Logger.log_level = ::Logger::INFO

describe Omega::Client::Ship do
  before(:each) do
    @ship1    = FactoryGirl.build(:ship1)
    @ship2    = FactoryGirl.build(:ship2)
    @station1 = FactoryGirl.build(:station1)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_LOCATIONS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)
  end

  it "should be remotely trackable" do
    cship2 = Omega::Client::Ship.get('ship2')
    cship2.id.should == @ship2.id
    cship2.object_id.should_not == @ship2.object_id
  end

  it "should have remotely trackable location" do
    nloc = @ship2.location + [100, 0, 0]
    cship2 = Omega::Client::Ship.get('ship2')
    times_invoked = 0
    cship2.handle_event(:movement, 1) { |loc|
      loc.id.should == cship2.location.id
      times_invoked += 1
    }

    Omega::Client::Node.invoke_request('manufactured::move_entity', @ship2.id, nloc)
    sleep 3
    times_invoked.should >= 1
  end

  it "should be in a system" do
    cstat1 = Omega::Client::Station.get('station1')
    cship2 = Omega::Client::Ship.get('ship2')
    cship2.solar_system.name.should == @ship2.system_name
    cship2.closest(:station).first.id.should == cstat1.id

    nloc = @ship2.location + [100, 0, 0]
    cship2.move_to :location => nloc
    Manufactured::Registry.instance.ships.find { |s| s.id == @ship2.id }.location.movement_strategy.class.should == Motel::MovementStrategies::Linear
  end

  it "should interact with environment" do
    cship1 = Omega::Client::Ship.get('ship1')
    cship2 = Omega::Client::Ship.get('ship2')
    transferred_event = false
    cship2.handle_event(:transferred) { |from, to, rs, q|
      transferred_event = true
    }
    cship2.transfer 50, :of => 'metal-alluminum', :to => cship1
    Manufactured::Registry.instance.ships.find { |s| s.id == @ship2.id }.resources.should be_empty
    Manufactured::Registry.instance.ships.find { |s| s.id == @ship1.id }.resources.should_not be_empty
    transferred_event.should be_true
    # TODO test defended events
  end
end

describe Omega::Client::Miner do
  before(:each) do
    @ship1    = FactoryGirl.build(:ship1)
    @ship2    = FactoryGirl.build(:ship2)
    @ship5    = FactoryGirl.build(:ship5)
    @ship6    = FactoryGirl.build(:ship6)
    @ship7    = FactoryGirl.build(:ship7)
    @stat5    = FactoryGirl.build(:station5)
    @stat6    = FactoryGirl.build(:station6)

    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)

  end

  it "should validate ship type" do
    sh1 = Omega::Client::Miner.get('ship1')
    sh2 = Omega::Client::Miner.get('ship2')
    sh1.should be_nil
    sh2.should_not be_nil
  end

  # test resource_collected, mining_stopped

  it "should detect cargo state" do
    # XXX need to preload a client station for 'closest' call in miner
    cstat5 = Omega::Client::Station.get('station5')

    cship5 = Omega::Client::Ship.get('ship5')
    cship6 = Omega::Client::Miner.get('ship6')

    cship6.transfer 100, :of => 'metal-steel', :to => cship5
    cship6.cargo_full?.should be_false
    cship6.instance_variable_get(:@current_states).should_not include(:cargo_full)

    cship5.transfer 100, :of => 'metal-steel', :to => cship6
    cship6.cargo_full?.should be_true
    cship6.instance_variable_get(:@current_states).should include(:cargo_full)
  end

  it "should offload resources" do
    # load client entities
    cstat6 = Omega::Client::Station.get('station6')
    cship6 = Omega::Client::Miner.get('ship6')

    cship6.offload_resources
    cship6.resources.should be_empty
    cstat6.resources.keys.should include('metal-steel')
    cstat6.resources['metal-steel'].should == 100
    # TODO test moving to next mining target?
  end

  it "should move to offload resources" do
    # load client entities
    cstat5 = Omega::Client::Station.get('station5')
    cship3 = Omega::Client::Miner.get('ship3')

    cship3.offload_resources
    cship3.location.movement_strategy.class.should == Motel::MovementStrategies::Linear
    # TODO should do this but adds over a minute to tests, perhaps move locations closer
    #time = ((cship6.location - cstat5.location) / cship6.location.movement_strategy.speed) + 1
    #sleep time
    #cship6.resources.should be_empty
    #cstat6.resources.keys.should include('metal-steel')
    #cstat6.resources['metal-steel'].should == 100
  end

  it "should select mining target" do
    cship7 = Omega::Client::Miner.get('ship7')

    cship7.select_target
    cship7.mining?.should be_true
    cship7.mining.entity.name.should == 'ast2'
  end

  it "should move to next mining target" do
    # XXX need to preload a client station for 'closest' call in miner
    cstat5 = Omega::Client::Station.get('station5')

    cship3 = Omega::Client::Miner.get('ship3')

    cship3.select_target
    cship3.location.movement_strategy.class.should == Motel::MovementStrategies::Linear
    # TODO sleep & then verify mining
  end
end

describe Omega::Client::Corvette do
  before(:each) do
    @ship2    = FactoryGirl.build(:ship2)
    @ship4    = FactoryGirl.build(:ship4)

    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_LOCATIONS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)
  end

  it "should validate ship type" do
    sh2 = Omega::Client::Corvette.get('ship2')
    sh4 = Omega::Client::Corvette.get('ship4')
    sh2.should be_nil
    sh4.should_not be_nil
  end

  it "should run patrol route" do
  end

  it "should check proximity for enemies" do
    cship4 = Omega::Client::Corvette.get('ship4')
    cship4.check_proximity
    ac = Manufactured::Registry.instance.attack_commands.find { |i,ac| ac.attacker.id == 'ship4' }.last
    ac.should_not be_nil
    ac.attacker.id.should == 'ship4'
    ac.defender.id.should == 'ship5'
    # TODO test attacked events
  end
end
