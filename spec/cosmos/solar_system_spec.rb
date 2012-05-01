# solar_system module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Cosmos::SolarSystem do

  it "should successfully accept and set solar_system params" do
     solar_system   = Cosmos::SolarSystem.new :name => 'solar_system1'
     solar_system.name.should == 'solar_system1'
     solar_system.location.should_not be_nil
     solar_system.location.x.should == 0
     solar_system.location.y.should == 0
     solar_system.location.z.should == 0
     solar_system.star.should be_nil
     solar_system.galaxy.should be_nil
     solar_system.planets.size.should == 0
     solar_system.asteroids.size.should == 0
     solar_system.jump_gates.size.should == 0
  end

  it "should be able to be remotely trackable" do
    Cosmos::SolarSystem.remotely_trackable?.should be_true
    ss = Cosmos::SolarSystem.new :remote_queue => 'foozbar'
    ss.remote_queue.should == 'foozbar'
  end

  it "should permit adding children" do
    solar_system    = Cosmos::SolarSystem.new
    star      = Cosmos::Star.new
    planet1   = Cosmos::Planet.new
    planet2   = Cosmos::Planet.new
    asteroid1 = Cosmos::Asteroid.new
    jump_gate = Cosmos::JumpGate.new

    # always true, change?
    solar_system.has_children?.should be_true

    solar_system.add_child(planet1)
    solar_system.children.size.should == 1
    solar_system.planets.size.should == 1
    solar_system.children.include?(planet1).should be_true
    solar_system.children.include?(planet2).should be_false
    solar_system.has_children?.should be_true
    planet1.location.parent_id.should == solar_system.location.id

    solar_system.add_child(planet1)
    solar_system.children.size.should == 1

    solar_system.add_child(Cosmos::Galaxy.new)
    solar_system.children.size.should == 1

    solar_system.add_child(planet2)
    solar_system.children.size.should == 2
    solar_system.children.include?(planet2).should be_true

    solar_system.add_child(asteroid1)
    solar_system.children.size.should == 3

    solar_system.add_child(star)
    solar_system.add_child(jump_gate)
    solar_system.children.size.should == 5
    solar_system.children.should include(planet1)
    solar_system.children.should include(planet2)
    solar_system.children.should include(star)
    solar_system.children.should include(jump_gate)
    solar_system.children.should include(asteroid1)
  end

  it "should permit removing children" do
    solar_system    = Cosmos::SolarSystem.new
    star      = Cosmos::Star.new
    planet1   = Cosmos::Planet.new
    planet2   = Cosmos::Planet.new
    asteroid1 = Cosmos::Asteroid.new :name => 'asteroid1'
    jump_gate = Cosmos::JumpGate.new

    solar_system.add_child(star)
    solar_system.add_child(planet1)
    solar_system.add_child(planet2)
    solar_system.add_child(asteroid1)
    solar_system.add_child(jump_gate)
    solar_system.children.size.should == 5

    solar_system.remove_child(star)
    solar_system.children.size.should == 4

    solar_system.remove_child(planet1)
    solar_system.children.size.should == 3

    solar_system.remove_child(planet1)
    solar_system.children.size.should == 3

    solar_system.remove_child(asteroid1.name)
    solar_system.children.size.should == 2
  end

  it "should provide means to traverse all descendants, invoking optional block arg" do
    solar_system    = Cosmos::SolarSystem.new
    star      = Cosmos::Star.new
    planet    = Cosmos::Planet.new
    jump_gate = Cosmos::JumpGate.new
    asteroid  = Cosmos::Asteroid.new
    moon      = Cosmos::Moon.new

    solar_system.add_child(star)
    solar_system.add_child(planet)
    solar_system.add_child(asteroid)
    solar_system.add_child(jump_gate)
    planet.add_child(moon)

    i = 0 
    solar_system.each_child { |parent, desc|
      i += 1
    }   

    i.should == 5
  end

  it "should be convertable to json" do
    g = Cosmos::SolarSystem.new(:name => 'solar_system1',
                           :location => Motel::Location.new(:x => 50))
    g.add_child(Cosmos::Planet.new(:name => 'planet1'))

    j = g.to_json
    j.should include('"json_class":"Cosmos::SolarSystem"')
    j.should include('"name":"solar_system1"')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"x":50')
    j.should include('"json_class":"Cosmos::Planet"')
    j.should include('"name":"planet1"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Cosmos::SolarSystem","data":{"star":null,"planets":[{"json_class":"Cosmos::Planet","data":{"moons":[],"color":"21f798","size":14,"name":"planet1","location":{"json_class":"Motel::Location","data":{"z":0,"restrict_view":true,"x":0,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"remote_queue":null,"parent_id":null,"id":null,"y":0}}}}],"name":"solar_system1","jump_gates":[],"background":"system5","location":{"json_class":"Motel::Location","data":{"z":null,"restrict_view":true,"x":50,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"remote_queue":null,"parent_id":null,"id":null,"y":null}}}}'
    g = JSON.parse(j)

    g.class.should == Cosmos::SolarSystem
    g.name.should == 'solar_system1'
    g.location.x.should  == 50
    g.planets.size.should == 1
    g.planets.first.name.should == 'planet1'
  end

end
