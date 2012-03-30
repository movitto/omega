# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'
require 'rjr/local_node'

describe Cosmos::RJRAdapter do

  before(:all) do
    Motel::RJRAdapter.init
    Users::RJRAdapter.init
    Cosmos::RJRAdapter.init
    @local_node = RJR::LocalNode.new :node_id => 'omega-test'
  end

  before(:each) do
    Motel::Runner.instance.clear
    Cosmos::Registry.instance.init
  end

  after(:all) do
  end

  it "should permit users with create entities to create_entity" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy43', :location => Motel::Location.new(:id => 50)
    sys1 = Cosmos::SolarSystem.new :name => 'system42', :location => Motel::Location.new(:id => 51)
    u = TestUser.create.login(@local_node).clear_privileges

    lambda{
      @local_node.invoke_request('cosmos::create_entity', gal1, :universe)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('create', 'cosmos_entities')

    lambda{
      gal = @local_node.invoke_request('cosmos::create_entity', gal1, :universe)
      gal.class.should == Cosmos::Galaxy
      gal.name.should == gal1.name
    }.should_not raise_error

    gal = Cosmos::Registry.instance.find_entity :type => :galaxy, :name => 'galaxy43'
    gal.class.should == Cosmos::Galaxy
    gal.name.should == gal1.name
    Motel::Runner.instance.locations.size.should == 1
    Motel::Runner.instance.locations.first.id.should == 50

    lambda{
      @local_node.invoke_request('cosmos::create_entity', sys1, 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      sys = @local_node.invoke_request('cosmos::create_entity', sys1, gal1)
      sys.class.should == Cosmos::SolarSystem
      sys.name.should == sys1.name
    #}.should raise_error(Omega::DataNotFound)
    }.should_not raise_error
  end

  it "should permit users with view cosmos_entities or view cosmos_entity-<id> to get_entity" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy42', :location => Motel::Location.new(:id => 15)
    gal2 = Cosmos::Galaxy.new :name => 'galaxy43', :location => Motel::Location.new(:id => 25)
    sys1 = Cosmos::SolarSystem.new :name => 'system42', :location => Motel::Location.new(:id => 35)
    star1= Cosmos::Star.new :name => 'star42', :location => Motel::Location.new(:id => 45)
    gal1.add_child(sys1)
    sys1.add_child(star1)
    u = TestUser.create.clear_privileges

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run gal2.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run star1.location
    Cosmos::Registry.instance.add_child gal1
    Cosmos::Registry.instance.add_child gal2

    lambda{
      gal = @local_node.invoke_request('cosmos::get_entity', 'galaxy')
      gal.class.should == Array
      gal.size.should == 0
    #}.should raise_error(Omega::PermissionError, "session not found")
    }.should_not raise_error

    u.login(@local_node).add_privilege('view', 'cosmos_entities')

    lambda{
      gal = @local_node.invoke_request('cosmos::get_entity', 'galaxy')
      gal.class.should == Array
      gal.size.should == 2
      gal.first.class.should == Cosmos::Galaxy
      gal.last.class.should == Cosmos::Galaxy
      gal.first.name.should == 'galaxy42'
      gal.last.name.should  == 'galaxy43'
      # TODO test galaxy locations retrieved are latest managed by motel
    }.should_not raise_error

    u.clear_privileges.add_privilege('view', 'cosmos_entity-' + gal1.id.to_s)

    lambda{
      gal = @local_node.invoke_request('cosmos::get_entity', 'galaxy')
      gal.class.should == Array
      gal.size.should == 1
      gal.first.class.should == Cosmos::Galaxy
      gal.first.name.should == 'galaxy42'

      gal = @local_node.invoke_request('cosmos::get_entity', 'galaxy', 'galaxy42')
      gal.class.should == Cosmos::Galaxy
      gal.name.should == 'galaxy42'
      # TODO test galaxy locations retrieved are latest managed by motel
    }.should_not raise_error

    lambda{
      @local_node.invoke_request('cosmos::get_entity', 'galaxy', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('cosmos::get_entity', 'galaxy', 'galaxy43')
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)
  end

  it "should permit users with view cosmos_entities or view cosmos_entity-<id> to get_entity_from_location" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy42', :location => Motel::Location.new(:id => 42)
    sys1 = Cosmos::SolarSystem.new :name => 'system42', :location => Motel::Location.new(:id => 43)
    gal1.add_child(sys1)
    u = TestUser.create.login(@local_node).clear_privileges

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Cosmos::Registry.instance.add_child gal1

    u.add_privilege('view', 'cosmos_entities')

    lambda{
      @local_node.invoke_request('cosmos::get_entity_from_location', 'galaxy', 43)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      sys = @local_node.invoke_request('cosmos::get_entity_from_location', 'solarsystem', 43)
      sys.class.should == Cosmos::SolarSystem
      sys.name.should == sys1.name
      # TODO test galaxy locations retrieved are latest managed by motel
    #}.should raise_error(Omega::DataNotFound)
    }.should_not raise_error
  end

  it "should permit local nodes to save and restore state" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy42'
    u = TestUser.create.login(@local_node).clear_privileges

    Cosmos::Registry.instance.add_child gal1
    Cosmos::Registry.instance.children.size.should == 1

    lambda{
      ret = @local_node.invoke_request('cosmos::save_state', '/tmp/cosmos-test')
      ret.should be_nil
    }.should_not raise_error

    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.children.size.should == 0

    lambda{
      ret = @local_node.invoke_request('cosmos::restore_state', '/tmp/cosmos-test')
      ret.should be_nil
    }.should_not raise_error

    Cosmos::Registry.instance.children.size.should == 1
    Cosmos::Registry.instance.children.first.name.should == gal1.name

    FileUtils.rm_f '/tmp/cosmos-test'
  end
end
