# planet module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Cosmos::Planet do

  it "should successfully accept and set planet params" do
     system = Cosmos::SolarSystem.new
     planet   = Cosmos::Planet.new :name => 'planet1', :solar_system => system
     planet.name.should == 'planet1'
     planet.location.should_not be_nil
     planet.location.x.should == 0
     planet.location.y.should == 0
     planet.location.z.should == 0
     planet.solar_system.should == system
     planet.moons.size.should == 0
     planet.parent.should == planet.solar_system

     planet.accepts_resource?(Cosmos::Resource.new(:name => 'what', :type => 'ever')).should be_false
  end

  it "should verify validity of planet" do
     plan   = Cosmos::Planet.new :name => 'planet1'
     plan.valid?.should be_true

     plan.name = 11111
     plan.valid?.should be_false

     plan.name = nil
     plan.valid?.should be_false
     plan.name = 'planet1'

     plan.location = nil
     plan.valid?.should be_false
     plan.location = Motel::Location.new

     plan.moons << 1
     plan.valid?.should be_false

     plan.moons.clear
     plan.moons << Cosmos::Moon.new(:name => 'abc')
     plan.valid?.should be_true

     plan.moons.first.name = 22222
     plan.valid?.should be_false
  end


  it "should accept movement strategy to use" do
    planet = Cosmos::Planet.new :movement_strategy => Motel::MovementStrategies::Elliptical.new(:speed => 10, :e => 0.5, :p => 10)
    planet.location.movement_strategy.class.should be(Motel::MovementStrategies::Elliptical)
    planet.location.movement_strategy.speed.should == 10
    planet.location.movement_strategy.e.should == 0.5
    planet.location.movement_strategy.p.should == 10
  end

  it "should be not able to be remotely trackable" do
    Cosmos::Planet.remotely_trackable?.should be_false
  end

  it "should permit adding children" do
    planet    = Cosmos::Planet.new :name => 'pl1'
    moon1   = Cosmos::Moon.new :name => 'mn1'
    moon2   = Cosmos::Moon.new :name => 'mn2'

    planet.has_children?.should be_false

    planet.add_child(moon1)
    planet.children.size.should == 1
    planet.moons.size.should == 1
    planet.children.include?(moon1).should be_true
    planet.children.include?(moon2).should be_false
    planet.has_children?.should be_true
    moon1.location.parent_id.should == planet.location.id
    moon1.planet.should == planet

    lambda{
      planet.add_child(moon1)
    }.should raise_error(ArgumentError, "moon name mn1 is already taken")
    planet.children.size.should == 1

    lambda{
      planet.add_child(Cosmos::Galaxy.new)
    }.should raise_error(ArgumentError, "child must be a moon")
    planet.children.size.should == 1

    planet.add_child(moon2)
    planet.children.size.should == 2
    planet.children.include?(moon2).should be_true
    moon2.planet.should == planet
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

  it "should raise error if adding invalid child entity" do
    planet    = Cosmos::Planet.new
    moon1   = Cosmos::Moon.new :name => 'moon1'
    moon1a  = Cosmos::Moon.new :name => 'moon1'
    moon2   = Cosmos::Moon.new :name => 44444
    asteroid  = Cosmos::Asteroid.new :name => 'asteroid1'

    lambda {
      planet.add_child(moon1)
    }.should_not raise_error

    lambda {
      planet.add_child(moon1)
    }.should raise_error(ArgumentError)

    lambda {
      planet.add_child(moon1a)
    }.should raise_error(ArgumentError)

    lambda {
      planet.add_child(moon2)
    }.should raise_error(ArgumentError)

    lambda {
      planet.add_child(asteroid)
    }.should raise_error(ArgumentError)

    lambda {
      planet.add_child(1)
    }.should raise_error(ArgumentError)
  end

  it "should provide means to traverse all descendants, invoking optional block arg" do
    planet    = Cosmos::Planet.new :name => 'pl1'
    moon      = Cosmos::Moon.new :name => 'mn1'

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
