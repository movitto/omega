# registry module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

require 'stringio'

describe Cosmos::Registry do

  it "provide acceses to managed cosmos entities" do
    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.children.size.should == 0

    Cosmos::Registry.instance.has_children?.should be_false

    galaxy1 = Cosmos::Galaxy.new :name => 'galaxy1', :location => Motel::Location.new(:id => 1)
    galaxy2 = Cosmos::Galaxy.new :name => 'galaxy2', :location => Motel::Location.new(:id => 2)
    system1 = Cosmos::SolarSystem.new :name => 'system1', :location => Motel::Location.new(:id => 3)
    system2 = Cosmos::SolarSystem.new :name => 'system2', :location => Motel::Location.new(:id => 4)
    star1   = Cosmos::Star.new :name => 'star1', :location => Motel::Location.new(:id => 5)
    star2   = Cosmos::Star.new :name => 'star2', :location => Motel::Location.new(:id => 6)
    planet  = Cosmos::Planet.new :name => 'planet', :location => Motel::Location.new(:id => 7)
    galaxy1.add_child(system1)
    galaxy1.add_child(system2)
    system1.add_child(star1)
    system2.add_child(star2)
    system2.add_child(planet)

    Cosmos::Registry.instance.add_child(galaxy1)
    Cosmos::Registry.instance.children.size.should == 1

    Cosmos::Registry.instance.has_children?.should be_true

    Cosmos::Registry.instance.add_child(galaxy1)
    Cosmos::Registry.instance.children.size.should == 1

    Cosmos::Registry.instance.add_child(system1)
    Cosmos::Registry.instance.children.size.should == 1

    Cosmos::Registry.instance.add_child(galaxy2)
    Cosmos::Registry.instance.children.size.should == 2

    entity = Cosmos::Registry.instance.find_entity :type => :galaxy
    entity.class.should == Array
    entity.size.should == 2
    entity.should include(galaxy1)
    entity.should include(galaxy2)

    entity = Cosmos::Registry.instance.find_entity :type => :star
    entity.class.should == Array
    entity.size.should == 2
    entity.should include(star1)
    entity.should include(star2)

    entity = Cosmos::Registry.instance.find_entity :type => :moon
    entity.class.should == Array
    entity.size.should == 0

    entity = Cosmos::Registry.instance.find_entity :type => :planet, :name => 'foobar'
    entity.should be_nil

    entity = Cosmos::Registry.instance.find_entity :type => :planet, :name => 'planet'
    entity.should == planet

    entity = Cosmos::Registry.instance.find_entity :type => :solarsystem, :location => 3
    entity.should == system1

    entity = Cosmos::Registry.instance.find_entity :type => :solarsystem, :location => 7 
    entity.should be_nil
  end

  it "should provide means to traverse all descendants, invoking optional block arg" do
   galaxy1 = Cosmos::Galaxy.new
   galaxy2 = Cosmos::Galaxy.new
   system1 = Cosmos::SolarSystem.new
   system2 = Cosmos::SolarSystem.new
   star1   = Cosmos::Star.new
   star2   = Cosmos::Star.new
   planet = Cosmos::Planet.new
   moon   = Cosmos::Moon.new
   galaxy1.add_child(system1)
   galaxy2.add_child(system2)
   system1.add_child(star1)
   system2.add_child(star2)
   system1.add_child(planet)
   planet.add_child(moon)

   Cosmos::Registry.instance.init
   Cosmos::Registry.instance.add_child galaxy1
   Cosmos::Registry.instance.add_child galaxy2

   i = 0 
   Cosmos::Registry.instance.each_child { |desc|
     i += 1
   }   

   i.should == 8
 end

  it "should save running cosmos entities to io object" do
    galaxy1 = Cosmos::Galaxy.new :name => 'galaxy1'
    galaxy2 = Cosmos::Galaxy.new :name => 'galaxy2'
    system1 = Cosmos::SolarSystem.new
    system2 = Cosmos::SolarSystem.new
    star1   = Cosmos::Star.new
    star2   = Cosmos::Star.new
    planet = Cosmos::Planet.new
    moon   = Cosmos::Moon.new
    galaxy1.add_child(system1)
    galaxy2.add_child(system2)
    system1.add_child(star1)
    system2.add_child(star2)
    system1.add_child(planet)
    planet.add_child(moon)

    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.add_child galaxy1
    Cosmos::Registry.instance.add_child galaxy2
    Cosmos::Registry.instance.children.size.should == 2

    sio = StringIO.new
    Cosmos::Registry.instance.save_state(sio)
    s = sio.string

    s.should include('"name":"galaxy1"')
    s.should include('"name":"galaxy2"')
    s.should include('"json_class":"Cosmos::Galaxy"')
  end

  it "should restore running locations from io object" do
    s = '{"json_class":"Cosmos::Galaxy","data":{"solar_systems":[{"json_class":"Cosmos::SolarSystem","data":{"star":{"json_class":"Cosmos::Star","data":{"color":"FFFF00","size":52,"name":null,"location":{"json_class":"Motel::Location","data":{"restrict_view":true,"z":0,"restrict_modify":true,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"x":0,"y":0,"parent_id":null,"id":null}}}},"background":"system4","planets":[{"json_class":"Cosmos::Planet","data":{"moons":[{"json_class":"Cosmos::Moon","data":{"name":null,"location":{"json_class":"Motel::Location","data":{"restrict_view":true,"z":0,"restrict_modify":true,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"x":0,"y":0,"parent_id":null,"id":null}}}}],"color":"eead14","size":19,"name":null,"location":{"json_class":"Motel::Location","data":{"restrict_view":true,"z":0,"restrict_modify":true,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"x":0,"y":0,"parent_id":null,"id":null}}}}],"jump_gates":[],"name":null,"location":{"json_class":"Motel::Location","data":{"restrict_view":true,"z":0,"restrict_modify":true,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"x":0,"y":0,"parent_id":null,"id":null}}}}],"background":"galaxy6","name":"galaxy1","location":{"json_class":"Motel::Location","data":{"restrict_view":true,"z":0,"restrict_modify":true,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"x":0,"y":0,"parent_id":null,"id":null}}}}' + "\n" +
        '{"json_class":"Cosmos::Galaxy","data":{"solar_systems":[{"json_class":"Cosmos::SolarSystem","data":{"star":{"json_class":"Cosmos::Star","data":{"color":"FFFF00","size":45,"name":null,"location":{"json_class":"Motel::Location","data":{"restrict_view":true,"z":0,"restrict_modify":true,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"x":0,"y":0,"parent_id":null,"id":null}}}},"background":"system4","planets":[],"jump_gates":[],"name":null,"location":{"json_class":"Motel::Location","data":{"restrict_view":true,"z":0,"restrict_modify":true,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"x":0,"y":0,"parent_id":null,"id":null}}}}],"background":"galaxy5","name":"galaxy2","location":{"json_class":"Motel::Location","data":{"restrict_view":true,"z":0,"restrict_modify":true,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"x":0,"y":0,"parent_id":null,"id":null}}}}'
    a = s.collect { |i| i }

    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.restore_state(a)
    Cosmos::Registry.instance.children.size.should == 2

    ids = Cosmos::Registry.instance.galaxies.collect { |l| l.name }
    ids.should include("galaxy1")
    ids.should include("galaxy2")
  end

end
