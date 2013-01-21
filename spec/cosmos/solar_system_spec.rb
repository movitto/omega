# solar_system module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Cosmos::SolarSystem do

  it "should successfully accept and set solar_system params" do
     galaxy = Cosmos::Galaxy.new
     solar_system   = Cosmos::SolarSystem.new :name => 'solar_system1', :galaxy => galaxy
     solar_system.name.should == 'solar_system1'
     solar_system.location.should_not be_nil
     solar_system.location.x.should == 0
     solar_system.location.y.should == 0
     solar_system.location.z.should == 0
     solar_system.star.should be_nil
     solar_system.galaxy.should == galaxy
     solar_system.planets.size.should == 0
     solar_system.asteroids.size.should == 0
     solar_system.jump_gates.size.should == 0
     solar_system.parent.should == solar_system.galaxy

     solar_system.accepts_resource?(Cosmos::Resource.new(:name => 'what', :type => 'ever')).should be_false
  end

  it "should verify validity of solar system" do
     sys   = Cosmos::SolarSystem.new :name => 'solarsystem1'
     sys.valid?.should be_true

     sys.name = 11111
     sys.valid?.should be_false

     sys.name = nil
     sys.valid?.should be_false
     sys.name = 'solarsystem1'

     sys.location = nil
     sys.valid?.should be_false
     sys.location = Motel::Location.new

     sys.planets << 1
     sys.valid?.should be_false

     sys.planets.clear
     sys.planets << Cosmos::Planet.new(:name => 'abc')
     sys.valid?.should be_true

     sys.planets.first.name = 22222
     sys.valid?.should be_false
     sys.planets.first.name = 'abc'

     sys.add_child Cosmos::Star.new(:name => 'sta')
     sys.valid?.should be_true

     sys.star.name = 22222
     sys.valid?.should be_false
     sys.star.name = 'sta'

     sys.asteroids.clear
     sys.asteroids << Cosmos::Asteroid.new(:name => 'ast')
     sys.valid?.should be_true

     sys.asteroids.first.name = 22222
     sys.valid?.should be_false
     sys.asteroids.first.name = 'ast'

     sys.jump_gates << Cosmos::JumpGate.new(:solar_system => sys)
     sys.valid?.should be_true

     sys.jump_gates << 1
     sys.valid?.should be_false
     sys.jump_gates.clear
  end

  it "should be able to be remotely trackable" do
    Cosmos::SolarSystem.remotely_trackable?.should be_true
    ss = Cosmos::SolarSystem.new :remote_queue => 'foozbar'
    ss.remote_queue.should == 'foozbar'
  end

  it "should permit adding children" do
    solar_system    = Cosmos::SolarSystem.new :name => 'sys1'
    solar_system2   = Cosmos::SolarSystem.new :name => 'sys2'
    star      = Cosmos::Star.new :name => 'st1'
    planet1   = Cosmos::Planet.new :name => 'pla1'
    planet2   = Cosmos::Planet.new :name => 'pla2'
    asteroid1 = Cosmos::Asteroid.new :name => 'ast1'
    jump_gate = Cosmos::JumpGate.new :solar_system => solar_system, :endpoint => solar_system2

    # always true, change?
    solar_system.has_children?.should be_false

    solar_system.add_child(planet1)
    solar_system.children.size.should == 1
    solar_system.planets.size.should == 1
    solar_system.children.include?(planet1).should be_true
    solar_system.children.include?(planet2).should be_false
    solar_system.has_children?.should be_true
    planet1.location.parent_id.should == solar_system.location.id
    planet1.solar_system.should == solar_system

    lambda{
      solar_system.add_child(planet1)
    }.should raise_error(ArgumentError, "planet name pla1 is already taken")
    solar_system.children.size.should == 1

    lambda{
      solar_system.add_child(Cosmos::Galaxy.new)
    }.should raise_error(ArgumentError, "child must be a planet, jump gate, asteroid, star")
    solar_system.children.size.should == 1

    solar_system.add_child(planet2)
    solar_system.children.size.should == 2
    solar_system.children.include?(planet2).should be_true
    planet2.solar_system.should == solar_system

    solar_system.add_child(asteroid1)
    solar_system.children.size.should == 3
    asteroid1.solar_system.should == solar_system

    solar_system.add_child(star)
    solar_system.add_child(jump_gate)
    solar_system.children.size.should == 5
    solar_system.children.should include(planet1)
    solar_system.children.should include(planet2)
    solar_system.children.should include(star)
    solar_system.children.should include(jump_gate)
    solar_system.children.should include(asteroid1)
    star.solar_system.should == solar_system
    jump_gate.solar_system.should == solar_system
  end

  it "should permit removing children" do
    solar_system    = Cosmos::SolarSystem.new :name => 'ss1'
    solar_system2   = Cosmos::SolarSystem.new :name => 'ss2'
    star      = Cosmos::Star.new :name => 'star1'
    planet1   = Cosmos::Planet.new :name => 'planet1'
    planet2   = Cosmos::Planet.new :name => 'planet2'
    asteroid1 = Cosmos::Asteroid.new :name => 'asteroid1'
    jump_gate = Cosmos::JumpGate.new :solar_system => solar_system, :endpoint => solar_system2

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

  it "should raise error if adding invalid child entity" do
    solar_system    = Cosmos::SolarSystem.new
    planet1   = Cosmos::Planet.new :name => 'planet1'
    planet1a  = Cosmos::Planet.new :name => 'planet1'
    planet2   = Cosmos::Planet.new :name => 33333
    asteroid  = Cosmos::Asteroid.new

    lambda {
      solar_system.add_child(planet1)
    }.should_not raise_error

    lambda {
      solar_system.add_child(planet1)
    }.should raise_error(ArgumentError)

    lambda {
      solar_system.add_child(planet1a)
    }.should raise_error(ArgumentError)

    lambda {
      solar_system.add_child(planet2)
    }.should raise_error(ArgumentError)

    lambda {
      solar_system.add_child(asteroid)
    }.should raise_error(ArgumentError)

    lambda {
      solar_system.add_child(1)
    }.should raise_error(ArgumentError)
  end

  it "should provide means to traverse all descendants, invoking optional block arg" do
    solar_system    = Cosmos::SolarSystem.new :name => 'system1'
    solar_system2   = Cosmos::SolarSystem.new :name => 'system2'
    star      = Cosmos::Star.new :name => 'st1'
    planet    = Cosmos::Planet.new :name => 'pl1'
    jump_gate = Cosmos::JumpGate.new :solar_system => solar_system, :endpoint => solar_system2
    asteroid  = Cosmos::Asteroid.new :name => 'ast1'
    moon      = Cosmos::Moon.new :name => 'mn1'

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
    g = Cosmos::Galaxy.new(:name => 'galaxy1')
    s = Cosmos::SolarSystem.new(:name => 'solar_system1', :galaxy => g,
                           :location => Motel::Location.new(:x => 50))
    s.add_child(Cosmos::Planet.new(:name => 'planet1'))

    j = s.to_json
    j.should include('"json_class":"Cosmos::SolarSystem"')
    j.should include('"name":"solar_system1"')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"x":50')
    j.should include('"galaxy_name":"galaxy1"')
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
