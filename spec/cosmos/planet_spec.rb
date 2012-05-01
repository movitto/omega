# planet module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Cosmos::Planet do

  it "should successfully accept and set planet params" do
     planet   = Cosmos::Planet.new :name => 'planet1'
     planet.name.should == 'planet1'
     planet.location.should_not be_nil
     planet.location.x.should == 0
     planet.location.y.should == 0
     planet.location.z.should == 0
     planet.solar_system.should be_nil
     planet.moons.size.should == 0
  end

  it "should be not able to be remotely trackable" do
    Cosmos::Planet.remotely_trackable?.should be_false
  end

  it "should permit adding children" do
    planet    = Cosmos::Planet.new
    moon1   = Cosmos::Moon.new
    moon2   = Cosmos::Moon.new

    planet.has_children?.should be_false

    planet.add_child(moon1)
    planet.children.size.should == 1
    planet.moons.size.should == 1
    planet.children.include?(moon1).should be_true
    planet.children.include?(moon2).should be_false
    planet.has_children?.should be_true
    moon1.location.parent_id.should == planet.location.id

    planet.add_child(moon1)
    planet.children.size.should == 1

    planet.add_child(Cosmos::Galaxy.new)
    planet.children.size.should == 1

    planet.add_child(moon2)
    planet.children.size.should == 2
    planet.children.include?(moon2).should be_true
  end

  it "should permit removing children" do
    planet    = Cosmos::Planet.new
    moon1   = Cosmos::Moon.new :name => 'moon1'
    moon2   = Cosmos::Moon.new :name => 'moon2'

    planet.add_child(moon1)
    planet.add_child(moon2)
    planet.children.size.should == 2

    planet.remove_child(moon1)
    planet.children.size.should == 1

    planet.remove_child(moon2.name)
    planet.children.size.should == 0
  end

  it "should provide means to traverse all descendants, invoking optional block arg" do
    planet    = Cosmos::Planet.new
    moon      = Cosmos::Moon.new

    planet.add_child(moon)

    i = 0 
    planet.each_child { |parent, desc|
      i += 1
    }   

    i.should == 1
  end

  it "should be convertable to json" do
    g = Cosmos::Planet.new(:name => 'planet1',
                           :location => Motel::Location.new(:x => 50))
    g.add_child(Cosmos::Moon.new(:name => 'moon1'))

    j = g.to_json
    j.should include('"json_class":"Cosmos::Planet"')
    j.should include('"name":"planet1"')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"x":50')
    j.should include('"json_class":"Cosmos::Moon"')
    j.should include('"name":"moon1"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Cosmos::Planet","data":{"moons":[{"json_class":"Cosmos::Moon","data":{"name":"moon1","location":{"json_class":"Motel::Location","data":{"z":0,"restrict_view":true,"x":0,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"remote_queue":null,"parent_id":null,"id":null,"y":0}}}}],"color":"e806c5","size":10,"name":"planet1","location":{"json_class":"Motel::Location","data":{"z":null,"restrict_view":true,"x":50,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"remote_queue":null,"parent_id":null,"id":null,"y":null}}}}'
    g = JSON.parse(j)

    g.class.should == Cosmos::Planet
    g.name.should == 'planet1'
    g.location.x.should  == 50
    g.moons.size.should == 1
    g.moons.first.name.should == 'moon1'
  end

end
