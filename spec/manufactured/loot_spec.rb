# loot module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Manufactured::Loot do

  it "should successfully accept and set loot params" do
     sys  = Cosmos::SolarSystem.new :name => 'system1'
     sys2 = Cosmos::SolarSystem.new :name => 'system2'
     loot = Manufactured::Loot.new :id => 'loot1',
                                   :solar_system => sys
                                   
     loot.id.should == 'loot1'
     loot.location.should_not be_nil
     loot.location.x.should == 0
     loot.location.y.should == 0
     loot.location.z.should == 0

     loot.parent.should == sys
     loot.parent = sys2
     loot.parent.should == sys2
  end

  it "should lookup parent system in registry if name given" do
     sys  = Cosmos::SolarSystem.new :name => 'system1'
     gal  = Cosmos::Galaxy.new :name => 'galaxy1', :solar_systems => [sys]
     Cosmos::Registry.instance.add_child gal

     loot = Manufactured::Loot.new :id => 'loot1', :system_name => 'system1'
     loot.solar_system.should == sys
  end

  it "should verify validity of loot" do
    sys = Cosmos::SolarSystem.new
    loot = Manufactured::Loot.new :id => 'loot1', :solar_system => sys
    loot.valid?.should be_true

    loot.id = nil
    loot.valid?.should be_false
    loot.id = 'ship1'

    loot.location = nil
    loot.valid?.should be_false
    loot.location = Motel::Location.new :x => 0, :y => 0, :z => 0

    loot.location.movement_strategy = Motel::MovementStrategies::Linear.new(:step_delay => 1, :speed => 5)
    loot.valid?.should be_false
    loot.location.movement_strategy = Motel::MovementStrategies::Stopped.instance

    loot.solar_system = nil
    loot.valid?.should be_false
    loot.solar_system = sys

    loot.valid?.should be_true
  end

  it "should set parent location when setting location" do
    sys1 = Cosmos::SolarSystem.new :location => Motel::Location.new(:id => 1)
    oloc = Motel::Location.new
    nloc = Motel::Location.new
    loot = Manufactured::Loot.new :id => 'loot1', :solar_system => sys1, :location => oloc
    loot.location = nloc
    nloc.parent.should == sys1.location
    sys1.location.children.should include(nloc)
    sys1.location.children.should_not include(oloc)
  end

  it "should set parent location when setting system" do
    sys1 = Cosmos::SolarSystem.new :location => Motel::Location.new(:id => 1)
    sys2 = Cosmos::SolarSystem.new :location => Motel::Location.new(:id => 1)
    loot = Manufactured::Loot.new :id => 'loot1', :solar_system => sys1
    loot.location.parent.should == sys1.location
    loot.solar_system = sys2
    loot.location.parent.should == sys2.location
  end

  it "should permit storing resources locally" do
    loot   = Manufactured::Loot.new :id => 'loot1'
    loot.resources.should be_empty
    loot.should be_empty
    
    res = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    loot.add_resource res.id, 10
    loot.should_not be_empty
    loot.resources.should_not be_empty
    loot.resources.size.should == 1
    loot.resources[res.id].should == 10
    loot.quantity.should == 10

    loot.add_resource res.id, 60
    loot.resources.size.should == 1
    loot.resources[res.id].should == 70
    loot.quantity.should == 70

    loot.remove_resource res.id, 40
    loot.resources.size.should == 1
    loot.resources[res.id].should == 30
    loot.quantity.should == 30

    # should remove resource if set to 0
    loot.remove_resource res.id, 30
    loot.resources.size.should == 0
    loot.quantity.should == 0
    loot.should be_empty
  end

  it "should raise error if cannot or remove resource" do
    loot   = Manufactured::Loot.new :id => 'loot1'
    loot.resources.should be_empty
    loot.should be_empty

    res = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    lambda{
      loot.remove_resource res.id, 1
    }.should raise_error(Omega::OperationError)
  end

  it "should return boolean indicating if loot is empty" do
    loot   = Manufactured::Loot.new :id => 'loot1'
    loot.should be_empty

    res1 = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    res2 = Cosmos::Resource.new :name => 'steel',    :type => 'metal'
    loot.add_resource res1.id, 20
    loot.add_resource res1.id, 30
    loot.should_not be_empty
  end

  it "should be convertable to json" do
    system1 = Cosmos::SolarSystem.new :name => 'system1'
    location= Motel::Location.new :id => 20, :y => -15
    res1    = Cosmos::Resource.new :name => 'titanium', :type => 'metal'

    l = Manufactured::Loot.new(:id => 'loot1', :solar_system => system1, 
                               :location => location,
                               :resources => {res1.id => 100})

    j = l.to_json
    j.should include('"json_class":"Manufactured::Loot"')
    j.should include('"id":"loot1"')
    j.should include('"'+res1.id+'":100')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"id":20')
    j.should include('"y":-15')
    j.should include('"system_name":"system1"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Manufactured::Loot","data":{"id":"loot1","location":{"json_class":"Motel::Location","data":{"id":20,"x":0,"y":-15.0,"z":0,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"movement_callbacks":[],"proximity_callbacks":[]}},"system_name":"system1","resources":{"metal-titanium":100}}}'
    l = JSON.parse(j)

    l.class.should == Manufactured::Loot
    l.id.should == "loot1"
    l.resources.size.should == 1
    l.resources.first.first.should == "metal-titanium"
    l.resources.first.last.should == 100
    l.location.should_not be_nil
    l.location.y.should == -15
    l.system_name.should == "system1"
  end

end
