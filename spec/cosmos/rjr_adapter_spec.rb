# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/local_node'

describe Cosmos::RJRAdapter do

  before(:each) do
    @nu1 = Users::User.new :id => 'user42', :password => 'foobar'
    @nu2 = Users::User.new :id => 'user43', :password => 'foobar'
    Users::Registry.instance.create @nu1
    Users::Registry.instance.create @nu2

    @gal1 = Cosmos::Galaxy.new      :name => 'galaxy43',
                                    :location => Motel::Location.new(:id => 10, :x => 10, :y => 10, :z => 10)

    @gal2 = Cosmos::Galaxy.new      :name => 'galaxy44',
                                    :location => Motel::Location.new(:id => 20, :x => 20, :y => 20, :z => 20)

    @sys1 = Cosmos::SolarSystem.new :name => 'system42',
                                    :location => Motel::Location.new(:id => 30, :x => 30, :y => 30, :z => 30)

    @star1= Cosmos::Star.new        :name => 'star42',
                                    :location => Motel::Location.new(:id => 40, :x => 40, :y => 40, :z => 40)

    @ast1 = Cosmos::Asteroid.new :name => 'ast2'
    @res1 = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    @res2 = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    @res3 = Cosmos::Resource.new :name => 'steel', :type => 'metal'
    @ires1 = Cosmos::Resource.new :name => 1111, :type => 2222
  end

  after(:each) do
    FileUtils.rm_f '/tmp/cosmos-test' if File.exists?('/tmp/cosmos-test')
  end

  it "should permit users with create entities to create_entity" do
    TestUser.add_privilege 'view', 'cosmos_entities'

    lambda{
      Omega::Client::Node.invoke_request('cosmos::create_entity', @gal1, :universe)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    old = Motel::Runner.instance.locations.size

    TestUser.add_privilege('create', 'cosmos_entities')

    lambda{
      Omega::Client::Node.invoke_request('cosmos::create_entity', 1, :universe)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    Motel::Runner.instance.locations.size.should == old

    lambda{
      gal = Omega::Client::Node.invoke_request('cosmos::create_entity', @gal1, :universe)
      gal.class.should == Cosmos::Galaxy
      gal.name.should == @gal1.name
    }.should_not raise_error

    gal = Cosmos::Registry.instance.find_entity :type => :galaxy, :name => 'galaxy43'
    gal.class.should == Cosmos::Galaxy
    gal.name.should == @gal1.name
    Motel::Runner.instance.locations.size.should == old + 1
    Motel::Runner.instance.locations.first.id.should_not be_nil
    gloc = Motel::Runner.instance.locations.find { |l| l.id == @gal1.location.id }
    gloc.should_not be_nil
    gloc.restrict_view.should be_false

    #lambda{
    #  @local_node.invoke_request('cosmos::create_entity', sys1, 'non_existant')
    ##}.should raise_error(Omega::DataNotFound)
    #}.should raise_error(Exception)

    lambda{
      sys = Omega::Client::Node.invoke_request('cosmos::create_entity', @sys1, @gal1.name)
      sys.class.should == Cosmos::SolarSystem
      sys.name.should == @sys1.name
    }.should_not raise_error

    Motel::Runner.instance.locations.size.should == old + 2

    sys = Cosmos::Registry.instance.find_entity :type => :solarsystem, :name => 'system42'
    sys.class.should == Cosmos::SolarSystem
    sys.name.should == @sys1.name
    sys.galaxy.should_not be_nil
    sys.galaxy.should == gal
    sys.location.parent.should == gal.location
    sys.location.restrict_view.should be_false
  end

  it "should verify entity names are unique when creating entities" do
    TestUser.add_privilege('create', 'cosmos_entities')

    old = Motel::Runner.instance.locations.size

    lambda{
      gal = Omega::Client::Node.invoke_request('cosmos::create_entity', @gal1, :universe)
      gal.class.should == Cosmos::Galaxy
      gal.name.should == @gal1.name
    }.should_not raise_error

    Motel::Runner.instance.locations.size.should == old + 1

    lambda{
      sys = Omega::Client::Node.invoke_request('cosmos::create_entity', @sys1, @gal1.name)
      sys.class.should == Cosmos::SolarSystem
      sys.name.should == @sys1.name
      sys = Omega::Client::Node.invoke_request('cosmos::create_entity', @sys1, @gal1.name)
    #}.should raise_error(ArgumentError)
    }.should raise_error

    Motel::Runner.instance.locations.size.should == old + 2
  end


  it "should permit users with view cosmos_entities or view cosmos_entity-<id> to get_entity" do
    @gal1.add_child(@sys1)
    @sys1.add_child(@star1)
    Motel::Runner.instance.run @gal1.location
    Motel::Runner.instance.run @gal2.location
    Motel::Runner.instance.run @sys1.location
    Motel::Runner.instance.run @star1.location
    Cosmos::Registry.instance.add_child @gal1
    Cosmos::Registry.instance.add_child @gal2

    # not logged in
    #lambda{
    #  gal = @local_node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy')
    #  gal.class.should == Array
    #  gal.size.should == 0
    ##}.should raise_error(Omega::PermissionError, "session not found")
    #}.should_not raise_error

    TestUser.add_privilege('view', 'cosmos_entities')

    lambda{
      gal = Omega::Client::Node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy')
      gal.class.should == Array
      gal.size.should == Cosmos::Registry.instance.children.size
      gal.find { |g| !g.is_a?(Cosmos::Galaxy) }.should be_nil
      gal.find { |g| g.location.nil? }.should be_nil
      gal.find { |g| g.name == @gal1.id }.should_not be_nil
      gal.find { |g| g.name == @gal2.id }.should_not be_nil
      gal.find { |g| g.location.id == @gal1.location.id }.should_not be_nil
      #gal.first.location.children.size.should == 1
      #gal.first.location.children.first.id.should == sys1.location.id
    }.should_not raise_error

    TestUser.clear_privileges.add_privilege('view', 'cosmos_entity-' + @gal1.name.to_s)

    lambda{
      gal = Omega::Client::Node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy')
      gal.class.should == Array
      gal.size.should == 1
      gal.first.class.should == Cosmos::Galaxy
      gal.first.name.should == @gal1.id

      gal = Omega::Client::Node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy', 'with_name', @gal1.id)
      gal.class.should == Cosmos::Galaxy
      gal.name.should == @gal1.id
    }.should_not raise_error

    lambda{
      Omega::Client::Node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy', 'with_name', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      Omega::Client::Node.invoke_request('cosmos::get_entity', 'of_type', 'galaxy', 'with_name', @gal2.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)
  end

  it "should permit users with view cosmos_entities or view cosmos_entity-<id> to get_entity from location" do
    @gal1.add_child(@sys1)
    Motel::Runner.instance.run @gal1.location
    Motel::Runner.instance.run @sys1.location
    Cosmos::Registry.instance.add_child @gal1

    TestUser.add_privilege('view', 'cosmos_entities')

    lambda{
      Omega::Client::Node.invoke_request('cosmos::get_entity', 'of_type' 'galaxy', 'with_location', 43)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      sys = Omega::Client::Node.invoke_request('cosmos::get_entity', 'of_type', 'solarsystem', 'with_location', @sys1.location.id)
      sys.class.should == Cosmos::SolarSystem
      sys.name.should == @sys1.name
    #}.should raise_error(Omega::DataNotFound)
    }.should_not raise_error
  end

  it "should permit users with view cosmos_entities or view cosmos_entity-<id> to get_resource_sources (from entity id)" do
    Motel::Runner.instance.run @gal1.location
    Cosmos::Registry.instance.add_child @gal1
    @gal1.add_child @sys1
    @sys1.add_child @ast1
    Cosmos::Registry.instance.set_resource @ast1.name, @res1, 50
    Cosmos::Registry.instance.set_resource @ast1.name, @res2, 50
    Cosmos::Registry.instance.set_resource @ast1.name, @res3, 50

    lambda{
      Omega::Client::Node.invoke_request('cosmos::get_resource_sources', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      Omega::Client::Node.invoke_request('cosmos::get_resource_sources', @ast1.name)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('view', 'cosmos_entities')

    lambda{
      rrs = Omega::Client::Node.invoke_request('cosmos::get_resource_sources', @ast1.name)
      rrs.class.should == Array
      rrs.size.should == 3
      rrs.first.resource.id.should == 'gem-ruby'
      rrs.last.resource.id.should == @res3.id
    }.should_not raise_error
  end

  it "should permit users with modify cosmos_entities or modify cosmos_entity-<id> to set_resource" do
    Motel::Runner.instance.run @gal1.location
    Cosmos::Registry.instance.add_child @gal1
    @gal1.add_child(@sys1)
    @sys1.add_child(@ast1)

    # invalid entity
    lambda{
      Omega::Client::Node.invoke_request('cosmos::set_resource', 'non_existant', @res1, 50)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid entity
    lambda{
      Omega::Client::Node.invoke_request('cosmos::set_resource', :universe, @res1, 50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # invalid quantity
    lambda{
      Omega::Client::Node.invoke_request('cosmos::set_resource', @ast1.name, @res1, -50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # invalid resource
    lambda{
      Omega::Client::Node.invoke_request('cosmos::set_resource', @ast1.name, 1111, 50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # invalid resource
    lambda{
      Omega::Client::Node.invoke_request('cosmos::set_resource', @ast1.name, @ires1, 50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # valid inputs, no permissions
    lambda{
      Omega::Client::Node.invoke_request('cosmos::set_resource', @ast1.name, @res1, 50)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'cosmos_entities')

    # entity does not accept resource
    lambda{
      ret = Omega::Client::Node.invoke_request('cosmos::set_resource', @gal1.name, @res1, 50)
    #}.should raise_error(Omega::ArgumentError)
    }.should raise_error(Exception)

    # good call
    lambda{
      ret = Omega::Client::Node.invoke_request('cosmos::set_resource', @ast1.name, @res1, 50)
      ret.should be_nil
    }.should_not raise_error

    Cosmos::Registry.instance.resource_sources.find { |rs|
      rs.entity.name == @ast1.name && rs.resource.id == @res1.id
    }.should_not be_nil
  end

  it "should should remove resources when invoking set_resource with a quantity of 0" do
    TestUser.add_privilege('modify', 'cosmos_entities')

    Cosmos::Registry.instance.add_child @gal1
    @gal1.add_child(@sys1)
    @sys1.add_child(@ast1)

    oldc = Cosmos::Registry.instance.children.size
    oldr = Cosmos::Registry.instance.resource_sources.size

    lambda{
      ret = Omega::Client::Node.invoke_request('cosmos::set_resource', @ast1.name, @res1, 50)
      ret.should be_nil
    }.should_not raise_error
    Cosmos::Registry.instance.resource_sources.size.should == oldr + 1

    lambda{
      ret = Omega::Client::Node.invoke_request('cosmos::set_resource', @ast1.name, @res1, 0)
      ret.should be_nil
    }.should_not raise_error
    Cosmos::Registry.instance.resource_sources.size.should == oldr
  end

  it "should permit local nodes to save and restore state" do
    Cosmos::Registry.instance.add_child @gal1
    old = Cosmos::Registry.instance.children.size

    lambda{
      ret = Omega::Client::Node.invoke_request('cosmos::save_state', '/tmp/cosmos-test')
      ret.should be_nil
    }.should_not raise_error

    Cosmos::Registry.instance.init
    Cosmos::Registry.instance.children.size.should == 0

    lambda{
      ret = Omega::Client::Node.invoke_request('cosmos::restore_state', '/tmp/cosmos-test')
      ret.should be_nil
    }.should_not raise_error

    Cosmos::Registry.instance.children.size.should == old
    Cosmos::Registry.instance.children.find { |g| g.name == @gal1.name }.should_not be_nil
  end
end
