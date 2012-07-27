# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
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
    Motel::Runner.instance.stop
  end

  it "should permit users with create entities to create_entity" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy43', :location => Motel::Location.new
    sys1 = Cosmos::SolarSystem.new :name => 'system42', :location => Motel::Location.new(:id => 51)
    u = TestUser.create.login(@local_node).clear_privileges

    lambda{
      @local_node.invoke_request('cosmos::create_entity', gal1, :universe)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    Motel::Runner.instance.locations.size.should == 0

    u.add_privilege('create', 'cosmos_entities')

    lambda{
      @local_node.invoke_request('cosmos::create_entity', 1, :universe)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    Motel::Runner.instance.locations.size.should == 0

    lambda{
      gal = @local_node.invoke_request('cosmos::create_entity', gal1, :universe)
      gal.class.should == Cosmos::Galaxy
      gal.name.should == gal1.name
    }.should_not raise_error

    gal = Cosmos::Registry.instance.find_entity :type => :galaxy, :name => 'galaxy43'
    gal.class.should == Cosmos::Galaxy
    gal.name.should == gal1.name
    Motel::Runner.instance.locations.size.should == 1
    Motel::Runner.instance.locations.first.id.should_not be_nil
    gal.location.id.should == Motel::Runner.instance.locations.first.id

    #lambda{
    #  @local_node.invoke_request('cosmos::create_entity', sys1, 'non_existant')
    ##}.should raise_error(Omega::DataNotFound)
    #}.should raise_error(Exception)

    lambda{
      sys = @local_node.invoke_request('cosmos::create_entity', sys1, gal1.name)
      sys.class.should == Cosmos::SolarSystem
      sys.name.should == sys1.name
    }.should_not raise_error

    Motel::Runner.instance.locations.size.should == 2

    sys = Cosmos::Registry.instance.find_entity :type => :solarsystem, :name => 'system42'
    sys.class.should == Cosmos::SolarSystem
    sys.name.should == sys1.name
    sys.galaxy.should_not be_nil
    sys.galaxy.should == gal
    sys.location.parent.should == gal.location
  end

  it "should verify entity names are unique when creating entities" do
    gal1 = Cosmos::Galaxy.new :name => 'entity11', :location => Motel::Location.new(:id => 50)
    sys1 = Cosmos::SolarSystem.new :name => 'entity11', :location => Motel::Location.new(:id => 51)
    u = TestUser.create.login(@local_node).clear_privileges.add_privilege('create', 'cosmos_entities')

    lambda{
      gal = @local_node.invoke_request('cosmos::create_entity', gal1, :universe)
      gal.class.should == Cosmos::Galaxy
      gal.name.should == gal1.name
    }.should_not raise_error

    Motel::Runner.instance.locations.size.should == 1

    lambda{
      sys = @local_node.invoke_request('cosmos::create_entity', sys1, gal1.name)
      sys.class.should == Cosmos::SolarSystem
      sys.name.should == sys1.name
    #}.should raise_error(ArgumentError)
    }.should raise_error

    Motel::Runner.instance.locations.size.should == 1
  end


  it "should permit users with view cosmos_entities or view cosmos_entity-<id> to get_entity" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy42', :location => Motel::Location.new
    gal2 = Cosmos::Galaxy.new :name => 'galaxy43', :location => Motel::Location.new
    sys1 = Cosmos::SolarSystem.new :name => 'system42', :location => Motel::Location.new
    star1= Cosmos::Star.new :name => 'star42', :location => Motel::Location.new
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
      gal = @local_node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy')
      gal.class.should == Array
      gal.size.should == 0
    #}.should raise_error(Omega::PermissionError, "session not found")
    }.should_not raise_error

    u.login(@local_node).add_privilege('view', 'cosmos_entities')

    lambda{
      gal = @local_node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy')
      gal.class.should == Array
      gal.size.should == 2
      gal.first.class.should == Cosmos::Galaxy
      gal.last.class.should == Cosmos::Galaxy
      gal.first.name.should == 'galaxy42'
      gal.last.name.should  == 'galaxy43'
      gal.first.location.id.should_not be_nil
      gal.first.location.id.should == gal1.location.id
      #gal.first.location.children.size.should == 1
      #gal.first.location.children.first.id.should == sys1.location.id
    }.should_not raise_error

    u.clear_privileges.add_privilege('view', 'cosmos_entity-' + gal1.name.to_s)

    lambda{
      gal = @local_node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy')
      gal.class.should == Array
      gal.size.should == 1
      gal.first.class.should == Cosmos::Galaxy
      gal.first.name.should == 'galaxy42'

      gal = @local_node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy', 'with_name', 'galaxy42')
      gal.class.should == Cosmos::Galaxy
      gal.name.should == 'galaxy42'
    }.should_not raise_error

    lambda{
      @local_node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy', 'with_name', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy', 'with_name', 'galaxy43')
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)
  end

  it "should permit users with view cosmos_entities or view cosmos_entity-<id> to get_entity from location" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy42', :location => Motel::Location.new(:id => 42)
    sys1 = Cosmos::SolarSystem.new :name => 'system42', :location => Motel::Location.new(:id => 43)
    gal1.add_child(sys1)
    u = TestUser.create.login(@local_node).clear_privileges

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Cosmos::Registry.instance.add_child gal1

    u.add_privilege('view', 'cosmos_entities')

    lambda{
      @local_node.invoke_request('cosmos::get_entity', 'of_type' 'galaxy', 'with_location', 43)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      sys = @local_node.invoke_request('cosmos::get_entity', 'of_type', 'solarsystem', 'with_location', 43)
      sys.class.should == Cosmos::SolarSystem
      sys.name.should == sys1.name
    #}.should raise_error(Omega::DataNotFound)
    }.should_not raise_error
  end

  it "should permit users with view cosmos_entities or view cosmos_entity-<id> to get_resource_sources (from entity id)" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy42', :location => Motel::Location.new(:id => 42)
    sys1 = Cosmos::SolarSystem.new :name => 'system23'
    ast1 = Cosmos::Asteroid.new :name => 'astt2'
    res1 = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    res2 = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    res3 = Cosmos::Resource.new :name => 'steel', :type => 'metal'
    u = TestUser.create.login(@local_node).clear_privileges

    Motel::Runner.instance.run gal1.location
    Cosmos::Registry.instance.add_child gal1
    gal1.add_child sys1
    sys1.add_child ast1
    Cosmos::Registry.instance.set_resource ast1.name, res1, 50
    Cosmos::Registry.instance.set_resource ast1.name, res2, 50
    Cosmos::Registry.instance.set_resource ast1.name, res3, 50

    lambda{
      @local_node.invoke_request('cosmos::get_resource_sources', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('cosmos::get_resource_sources', ast1.name)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('view', 'cosmos_entities')

    lambda{
      rrs = @local_node.invoke_request('cosmos::get_resource_sources', ast1.name)
      rrs.class.should == Array
      rrs.size.should == 2
      rrs.first.resource.id.should == res1.id
      rrs.last.resource.id.should == res3.id
    }.should_not raise_error
  end

  it "should permit users with modify cosmos_entities or modify cosmos_entity-<id> to set_resource" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy42', :location => Motel::Location.new(:id => 42)
    sys1 = Cosmos::SolarSystem.new :name => 'system14'
    ast1 = Cosmos::Asteroid.new :name => 'asteroid33'
    res1 = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    invalid = Cosmos::Resource.new :name => 1111, :type => 2222
    u = TestUser.create.login(@local_node).clear_privileges

    Motel::Runner.instance.run gal1.location
    Cosmos::Registry.instance.add_child gal1
    gal1.add_child(sys1)
    sys1.add_child(ast1)

    Cosmos::Registry.instance.children.size.should == 1
    Cosmos::Registry.instance.resource_sources.size.should == 0

    # invalid entity
    lambda{
      @local_node.invoke_request('cosmos::set_resource', 'non_existant', res1, 50)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid entity
    lambda{
      @local_node.invoke_request('cosmos::set_resource', :universe, res1, 50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # invalid quantity
    lambda{
      @local_node.invoke_request('cosmos::set_resource', ast1.name, res1, -50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # invalid resource
    lambda{
      @local_node.invoke_request('cosmos::set_resource', ast1.name, 1111, 50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # invalid resource
    lambda{
      @local_node.invoke_request('cosmos::set_resource', ast1.name, invalid, 50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # valid inputs, no permissions
    lambda{
      @local_node.invoke_request('cosmos::set_resource', ast1.name, res1, 50)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'cosmos_entities')

    # entity does not accept resource
    lambda{
      ret = @local_node.invoke_request('cosmos::set_resource', gal1.name, res1, 50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # good call
    lambda{
      ret = @local_node.invoke_request('cosmos::set_resource', ast1.name, res1, 50)
      ret.should be_nil
    }.should_not raise_error

    Cosmos::Registry.instance.resource_sources.size.should == 1
  end

  it "should should remove resources when invoking set_resource with a quantity of 0" do
    gal1 = Cosmos::Galaxy.new :name => 'galaxy42', :location => Motel::Location.new(:id => 42)
    sys1 = Cosmos::SolarSystem.new :name => 'system14'
    ast1 = Cosmos::Asteroid.new :name => 'asteroid33'
    res1 = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    u = TestUser.create.login(@local_node).clear_privileges.add_privilege('modify', 'cosmos_entities')

    Cosmos::Registry.instance.add_child gal1
    gal1.add_child(sys1)
    sys1.add_child(ast1)

    Cosmos::Registry.instance.children.size.should == 1
    Cosmos::Registry.instance.resource_sources.size.should == 0
    lambda{
      ret = @local_node.invoke_request('cosmos::set_resource', ast1.name, res1, 50)
      ret.should be_nil
    }.should_not raise_error
    Cosmos::Registry.instance.resource_sources.size.should == 1

    lambda{
      ret = @local_node.invoke_request('cosmos::set_resource', ast1.name, res1, 0)
      ret.should be_nil
    }.should_not raise_error
    Cosmos::Registry.instance.resource_sources.size.should == 0
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
