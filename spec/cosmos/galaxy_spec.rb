# galaxy module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Cosmos::Galaxy do

  it "should successfully accept and set galaxy params" do
     galaxy   = Cosmos::Galaxy.new :name => 'galaxy1'
     galaxy.name.should == 'galaxy1'
     galaxy.location.should_not be_nil
     galaxy.location.x.should == 0
     galaxy.location.y.should == 0
     galaxy.location.z.should == 0
  end

  it "should be able to be remotely trackable" do
    Cosmos::Galaxy.remotely_trackable?.should be_true
    galaxy = Cosmos::Galaxy.new :remote_queue => 'foozbar'
    galaxy.remote_queue.should == 'foozbar'
  end

  it "should permit adding children" do
    galaxy    = Cosmos::Galaxy.new
    system1   = Cosmos::SolarSystem.new
    system2   = Cosmos::SolarSystem.new

    galaxy.has_children?.should be_false

    galaxy.add_child(system1)
    galaxy.children.size.should == 1
    galaxy.children.include?(system1).should be_true
    galaxy.children.include?(system2).should be_false
    galaxy.has_children?.should be_true
    system1.location.parent_id.should == galaxy.location.id

    galaxy.add_child(system1)
    galaxy.children.size.should == 1

    galaxy.add_child(Cosmos::Planet.new)
    galaxy.children.size.should == 1

    galaxy.add_child(system2)
    galaxy.children.size.should == 2
    galaxy.children.include?(system2).should be_true
  end

  it "should permit removing children" do
    galaxy    = Cosmos::Galaxy.new
    system1   = Cosmos::SolarSystem.new :name => 'system1'
    system2   = Cosmos::SolarSystem.new :name => 'system2'

    galaxy.has_children?.should be_false

    galaxy.add_child(system1)
    galaxy.add_child(system2)
    galaxy.children.size.should == 2

    galaxy.remove_child(system2)
    galaxy.children.size.should == 1

    galaxy.remove_child(system2)
    galaxy.children.size.should == 1

    galaxy.remove_child(system1.name)
    galaxy.children.size.should == 0
  end

  it "should provide means to traverse all descendants, invoking optional block arg" do
   galaxy = Cosmos::Galaxy.new
   system = Cosmos::SolarSystem.new
   star   = Cosmos::Star.new
   planet = Cosmos::Planet.new
   moon   = Cosmos::Moon.new
   galaxy.add_child(system)
   system.add_child(star)
   system.add_child(planet)
   planet.add_child(moon)

   i = 0 
   galaxy.each_child { |parent, desc|
     i += 1
   }   

   i.should == 4
  end

  it "should be convertable to json" do
    g = Cosmos::Galaxy.new(:name => 'galaxy1',
                           :location => Motel::Location.new(:x => 50))
    g.add_child(Cosmos::SolarSystem.new(:name => 'system1'))

    j = g.to_json
    j.should include('"json_class":"Cosmos::SolarSystem"')
    j.should include('"name":"galaxy1"')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"x":50')
    j.should include('"json_class":"Cosmos::SolarSystem"')
    j.should include('"name":"system1"')
  end

  it "should be convertable from json" do
    j = '{"data":{"background":"galaxy4","name":"galaxy1","solar_systems":[{"data":{"background":"system5","planets":[],"jump_gates":[],"name":"system1","star":null,"location":{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"z":0,"parent_id":null,"x":0,"restrict_view":true,"id":null,"restrict_modify":true,"y":0},"json_class":"Motel::Location"}},"json_class":"Cosmos::SolarSystem"}],"location":{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"z":null,"parent_id":null,"x":50,"restrict_view":true,"id":null,"restrict_modify":true,"y":null},"json_class":"Motel::Location"}},"json_class":"Cosmos::Galaxy"}'
    g = JSON.parse(j)

    g.class.should == Cosmos::Galaxy
    g.name.should == 'galaxy1'
    g.location.x.should  == 50
    g.solar_systems.size.should == 1
    g.solar_systems.first.name.should == 'system1'
  end

end
