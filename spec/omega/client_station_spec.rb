# client station tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Client::Station do
  before(:each) do
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
    cstat1 = Omega::Client::Ship.get('station1')
    cstat1.id.should == @station1.id
    cstat1.object_id.should_not == @station1.object_id
  end

  it "should be in a system" do
    cstat1 = Omega::Client::Station.get('station1')
    cstat1.solar_system.name.should == @station1.system_name
  end

end

describe Omega::Client::Factory do
  before(:each) do
    @station3 = FactoryGirl.build(:station3)
    @station8 = FactoryGirl.build(:station8)

    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_LOCATIONS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_CREATE,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)
  end

  it "should construct entities" do
    cstat3 = Omega::Client::Factory.get('station3')

    cstat3.construct 'Manufactured::Ship', :type => :mining, :id => 'fooship'
    sleep(Manufactured::Ship.construction_time(:mining)+1)
    Manufactured::Registry.instance.ships.find { |s| s.id == 'fooship' }.should_not be_nil
    # TODO detect constructed event
  end

  it "should pick system to jump to" do
    FactoryGirl.build(:sys1)
    FactoryGirl.build(:sys2)

    cstat3 = Omega::Client::Factory.get('station3')
    cstat3.pick_system
    cstat3.solar_system.name.should == 'sys3'
  end

  it "should start construction cycle" do
    sship6 = FactoryGirl.build(:ship6)
    cship6 = Omega::Client::Ship.get('ship6')

    sstat8 = Manufactured::Registry.instance.find(:id => 'station8').first
    cstat8 = Omega::Client::Factory.get('station8')
    cstat8.entity_type 'miner'

    olds =  Manufactured::Registry.instance.ships.length
    cstat8.start_construction
    Manufactured::Registry.instance.ships.length.should == olds

    sstat8.add_resource('metal-rock', 100)
    cstat8 = Omega::Client::Factory.get('station8')
    cstat8.entity_type 'miner'
    cstat8.start_construction
    sleep(Manufactured::Ship.construction_time(:mining)+1)
    Manufactured::Registry.instance.ships.length.should == olds + 1

    olds =  Manufactured::Registry.instance.ships.length
    cstat8 = Omega::Client::Factory.get('station8')
    cstat8.entity_type 'miner'
    cstat8.start_construction
    Manufactured::Registry.instance.ships.length.should == olds

    olds =  Manufactured::Registry.instance.ships.length
    cstat8 = Omega::Client::Factory.get('station8')
    cstat8.entity_type 'miner'
    cship6.transfer(100, :of => 'metal-steel', :to => cstat8)
    Manufactured::Registry.instance.ships.length.should == olds
  end
end

