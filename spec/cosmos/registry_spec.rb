# registry module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
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
    asteroid= Cosmos::Asteroid.new :name => 'asteroid', :location => Motel::Location.new(:id => 8)
    galaxy1.add_child(system1)
    galaxy1.add_child(system2)
    system1.add_child(star1)
    system2.add_child(star2)
    system2.add_child(planet)
    system2.add_child(asteroid)

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

    entity = Cosmos::Registry.instance.find_entity :type => :asteroid
    entity.class.should == Array
    entity.size.should == 1
    entity.first.should == asteroid

    entity = Cosmos::Registry.instance.find_entity :type => :planet, :name => 'foobar'
    entity.should be_nil

    entity = Cosmos::Registry.instance.find_entity :type => :planet, :name => 'planet'
    entity.should == planet

    entity = Cosmos::Registry.instance.find_entity :type => :solarsystem, :location => 3
    entity.should == system1

    entity = Cosmos::Registry.instance.find_entity :type => :solarsystem, :location => 7 
    entity.should be_nil
  end

  # FIXME test registery.remove_child

  it "should provide means to traverse all descendants, invoking optional block arg" do
   galaxy1 = Cosmos::Galaxy.new
   galaxy2 = Cosmos::Galaxy.new
   system1 = Cosmos::SolarSystem.new
   system2 = Cosmos::SolarSystem.new
   star1   = Cosmos::Star.new
   star2   = Cosmos::Star.new
   planet = Cosmos::Planet.new
   moon   = Cosmos::Moon.new
   asteroid = Cosmos::Asteroid.new
   galaxy1.add_child(system1)
   galaxy2.add_child(system2)
   system1.add_child(star1)
   system2.add_child(star2)
   system1.add_child(planet)
   system1.add_child(asteroid)
   planet.add_child(moon)

   Cosmos::Registry.instance.init
   Cosmos::Registry.instance.add_child galaxy1
   Cosmos::Registry.instance.add_child galaxy2

   i = 0 
   Cosmos::Registry.instance.each_child { |parent, desc|
     i += 1
   }   

   i.should == 9
 end

  it "provide acceses to managed resource sources" do
    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.resource_sources.size.should == 0

    resource = Cosmos::Resource.new :name => 'ruby', :type => 'gem'

    Cosmos::Registry.instance.set_resource('non_existant', resource, 50)
    Cosmos::Registry.instance.resource_sources.size.should == 0

    galaxy1 = Cosmos::Galaxy.new :name => 'galaxy1'
    Cosmos::Registry.instance.add_child(galaxy1)

    Cosmos::Registry.instance.set_resource(galaxy1.name, resource, -10)
    Cosmos::Registry.instance.resource_sources.size.should == 0

    Cosmos::Registry.instance.set_resource(galaxy1.name, resource, 50)
    Cosmos::Registry.instance.resource_sources.size.should == 1
    Cosmos::Registry.instance.resource_sources.first.entity.should == galaxy1
    Cosmos::Registry.instance.resource_sources.first.resource.should == resource
    Cosmos::Registry.instance.resource_sources.first.quantity.should == 50

    Cosmos::Registry.instance.set_resource(galaxy1.name, resource, 30)
    Cosmos::Registry.instance.resource_sources.size.should == 1
    Cosmos::Registry.instance.resource_sources.first.entity.should == galaxy1
    Cosmos::Registry.instance.resource_sources.first.resource.should == resource
    Cosmos::Registry.instance.resource_sources.first.quantity.should == 30
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

    resource = Cosmos::Resource.new :name => 'ruby', :type => 'gem'

    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.add_child galaxy1
    Cosmos::Registry.instance.add_child galaxy2
    Cosmos::Registry.instance.children.size.should == 2

    Cosmos::Registry.instance.set_resource(galaxy1.name, resource, 10)
    Cosmos::Registry.instance.resource_sources.size.should == 1

    sio = StringIO.new
    Cosmos::Registry.instance.save_state(sio)
    s = sio.string

    s.should include('"name":"galaxy1"')
    s.should include('"name":"galaxy2"')
    s.should include('"json_class":"Cosmos::Galaxy"')
    s.should include('"json_class":"Cosmos::ResourceSource"')
    s.should include('"json_class":"Cosmos::Resource"')
    s.should include('"name":"ruby"')
    s.should include('"type":"gem"')
    s.should include('"quantity":10')
  end

  it "should restore running locations from io object" do
    s = '{"json_class":"Cosmos::Galaxy","data":{"solar_systems":[{"json_class":"Cosmos::SolarSystem","data":{"background":"system1","planets":[{"json_class":"Cosmos::Planet","data":{"color":"5fa1b9","moons":[{"json_class":"Cosmos::Moon","data":{"name":null,"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}}],"size":19,"name":null,"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}}],"jump_gates":[],"star":{"json_class":"Cosmos::Star","data":{"color":"FFFF00","size":49,"name":null,"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}},"name":null,"asteroids":[],"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}}],"background":"galaxy3","name":"galaxy1","location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}}' + "\n" +
        '{"json_class":"Cosmos::Galaxy","data":{"solar_systems":[{"json_class":"Cosmos::SolarSystem","data":{"background":"system2","planets":[],"jump_gates":[],"star":{"json_class":"Cosmos::Star","data":{"color":"FFFF00","size":44,"name":null,"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}},"name":null,"asteroids":[],"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}}],"background":"galaxy1","name":"galaxy2","location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}}' + "\n" +
        '{"json_class":"Cosmos::ResourceSource","data":{"resource":{"json_class":"Cosmos::Resource","data":{"type":"gem","name":"ruby"}},"entity":{"json_class":"Cosmos::Galaxy","data":{"solar_systems":[{"json_class":"Cosmos::SolarSystem","data":{"background":"system1","planets":[{"json_class":"Cosmos::Planet","data":{"color":"5fa1b9","moons":[{"json_class":"Cosmos::Moon","data":{"name":null,"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}}],"size":19,"name":null,"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}}],"jump_gates":[],"star":{"json_class":"Cosmos::Star","data":{"color":"FFFF00","size":49,"name":null,"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}},"name":null,"asteroids":[],"location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}}],"background":"galaxy3","name":"galaxy1","location":{"json_class":"Motel::Location","data":{"parent_id":null,"restrict_view":true,"z":0,"restrict_modify":true,"x":0,"remote_queue":null,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"id":null,"y":0}}}},"quantity":10}}' + "\n"
    a = s.collect { |i| i }

    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.restore_state(a)
    Cosmos::Registry.instance.children.size.should == 2
    Cosmos::Registry.instance.resource_sources.size.should == 1

    ids = Cosmos::Registry.instance.galaxies.collect { |l| l.name }
    ids.should include("galaxy1")
    ids.should include("galaxy2")
  end

end
