# registry module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

require 'stringio'

describe Cosmos::Registry do

  it "should provide access to valid cosmos entity types" do
    valid_types = Cosmos::Registry.instance.entity_types
    valid_types.should include(Cosmos::Galaxy)
    valid_types.should include(Cosmos::SolarSystem)
    valid_types.should include(Cosmos::Star)
    valid_types.should include(Cosmos::Planet)
    valid_types.should include(Cosmos::Moon)
    valid_types.should include(Cosmos::Asteroid)
    valid_types.should include(Cosmos::JumpGate)
    valid_types.should_not include(Integer)
  end

  it "should raise error if adding invalid child entity" do
    galaxy1  = Cosmos::Galaxy.new :name => 'galaxy1', :location => Motel::Location.new(:id => 1)
    galaxy1a = Cosmos::Galaxy.new :name => 'galaxy1'
    galaxy2  = Cosmos::Galaxy.new :name => 00000
    system1 = Cosmos::SolarSystem.new :name => 'system1', :location => Motel::Location.new(:id => 3)

    lambda {
      Cosmos::Registry.instance.add_child galaxy1
    }.should_not raise_error

    lambda {
      Cosmos::Registry.instance.add_child galaxy1
    }.should raise_error(ArgumentError)

    lambda {
      Cosmos::Registry.instance.add_child galaxy1a
    }.should raise_error(ArgumentError)

    lambda {
      Cosmos::Registry.instance.add_child galaxy2
    }.should raise_error(ArgumentError)

    lambda {
      Cosmos::Registry.instance.add_child system1
    }.should raise_error(ArgumentError)

    lambda {
      Cosmos::Registry.instance.add_child 1
    }.should raise_error(ArgumentError)
  end

  it "provide acceses to managed cosmos entities" do
    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.children.size.should == 0
    Cosmos::Registry.instance.has_children?.should be_false

    Cosmos::Registry.instance.name.should == "universe"
    Cosmos::Registry.instance.location.should == nil
    Cosmos::Registry.remotely_trackable?.should == false

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

    lambda{
      Cosmos::Registry.instance.add_child(galaxy1)
    }.should raise_error(ArgumentError, "galaxy name galaxy1 is already taken")
    Cosmos::Registry.instance.children.size.should == 1

    lambda{
      Cosmos::Registry.instance.add_child(system1)
    }.should raise_error(ArgumentError, "child must be a galaxy")
    Cosmos::Registry.instance.children.size.should == 1

    Cosmos::Registry.instance.add_child(galaxy2)
    Cosmos::Registry.instance.children.size.should == 2

    entity = Cosmos::Registry.instance.find_entity
    entity.class.should == Array
    entity.size.should == 8

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
   galaxy1 = Cosmos::Galaxy.new :name => 'galaxy1'
   galaxy2 = Cosmos::Galaxy.new :name => 'galaxy2'
   system1 = Cosmos::SolarSystem.new :name => 'system1'
   system2 = Cosmos::SolarSystem.new :name => 'system2'
   star1   = Cosmos::Star.new :name => 'star1'
   star2   = Cosmos::Star.new :name => 'star2'
   planet = Cosmos::Planet.new :name => 'planet'
   moon   = Cosmos::Moon.new :name => 'moon'
   asteroid = Cosmos::Asteroid.new :name => 'asteroid'
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

  it "should be convertable to json" do
    g1 = Cosmos::Galaxy.new(:name => 'galaxy1',
                            :location => Motel::Location.new(:x => 50))
    g1.add_child(Cosmos::SolarSystem.new(:name => 'system1'))
    g2 = Cosmos::Galaxy.new(:name => 'galaxy2',
                            :location => Motel::Location.new(:x => 60))

    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.add_child g1
    Cosmos::Registry.instance.add_child g2

    j = Cosmos::Registry.instance.to_json
    j.should include('"json_class":"Cosmos::Galaxy"')
    j.should include('"name":"galaxy1"')
    j.should include('"name":"galaxy2"')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"x":50')
    j.should include('"x":60')
    j.should include('"json_class":"Cosmos::SolarSystem"')
    j.should include('"name":"system1"')
  end

  it "should save running cosmos entities to io object" do
    galaxy1 = Cosmos::Galaxy.new :name => 'galaxy1'
    galaxy2 = Cosmos::Galaxy.new :name => 'galaxy2'
    system1 = Cosmos::SolarSystem.new :name => 'system1'
    system2 = Cosmos::SolarSystem.new :name => 'system2'
    star1   = Cosmos::Star.new :name => 'star1'
    star2   = Cosmos::Star.new :name => 'star2'
    planet = Cosmos::Planet.new :name => 'planet1'
    moon   = Cosmos::Moon.new :name => 'moon1'
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
    s = '{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"solar_systems":[{"data":{"jump_gates":[],"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"asteroids":[],"star":{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"size":41,"color":"FFFF00","name":"star1"},"json_class":"Cosmos::Star"},"background":"system4","name":"system1","remote_queue":null,"planets":[{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"moons":[{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"name":"moon1"},"json_class":"Cosmos::Moon"}],"size":13,"color":"9eca4b","name":"planet1"},"json_class":"Cosmos::Planet"}]},"json_class":"Cosmos::SolarSystem"}],"background":"galaxy5","name":"galaxy1","remote_queue":null},"json_class":"Cosmos::Galaxy"}'+ "\n" +
        '{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"solar_systems":[{"data":{"jump_gates":[],"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"asteroids":[],"star":{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"size":53,"color":"FFFF00","name":"star2"},"json_class":"Cosmos::Star"},"background":"system5","name":"system2","remote_queue":null,"planets":[]},"json_class":"Cosmos::SolarSystem"}],"background":"galaxy4","name":"galaxy2","remote_queue":null},"json_class":"Cosmos::Galaxy"}'+ "\n" +
        '{"data":{"quantity":10,"entity":{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"solar_systems":[{"data":{"jump_gates":[],"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"asteroids":[],"star":{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"size":41,"color":"FFFF00","name":"star1"},"json_class":"Cosmos::Star"},"background":"system4","name":"system1","remote_queue":null,"planets":[{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"moons":[{"data":{"location":{"data":{"restrict_view":true,"x":0,"restrict_modify":true,"children":[],"y":0,"z":0,"movement_callbacks":[],"proximity_callbacks":[],"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"remote_queue":null,"parent_id":null,"id":null},"json_class":"Motel::Location"},"name":"moon1"},"json_class":"Cosmos::Moon"}],"size":13,"color":"9eca4b","name":"planet1"},"json_class":"Cosmos::Planet"}]},"json_class":"Cosmos::SolarSystem"}],"background":"galaxy5","name":"galaxy1","remote_queue":null},"json_class":"Cosmos::Galaxy"},"resource":{"data":{"type":"gem","name":"ruby","id":"gem-ruby"},"json_class":"Cosmos::Resource"},"id":"b6e71417-4ab1-2912-6af0-1bc144f275a4"},"json_class":"Cosmos::ResourceSource"}' + "\n"
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
