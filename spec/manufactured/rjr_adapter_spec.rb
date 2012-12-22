# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/local_node'

describe Manufactured::RJRAdapter do

  before(:each) do
    ############## test users
    @testuser1 = Users::User.new :id => 'user42'
    @testuser2 = Users::User.new :id => 'user43'
    @u1 = Users::User.new :id => 'user1'
    @u2 = Users::User.new :id => 'user2'
    @ur1 = Users::Role.new :id => 'user_role_user1'
    @ur2 = Users::Role.new :id => 'user_role_user2'
    @u1.add_role(@ur1) ; @u2.add_role(@ur2)
    Users::Registry.instance.create @testuser1
    Users::Registry.instance.create @testuser2
    Users::Registry.instance.create @u1
    Users::Registry.instance.create @u2
    Users::Registry.instance.create @ur1
    Users::Registry.instance.create @ur2

    ############## test cosmos
    @gal1  = Cosmos::Galaxy.new      :name => 'ngal1',
                                     :location => Motel::Location.new(:id => '2000', :x => 10, :y => 10, :z => 10)
    @sys1  = Cosmos::SolarSystem.new :name => 'nsys1',
                                     :location => Motel::Location.new(:id => '2001', :x => 20, :y => 20, :z => 20)
    @sys2  = Cosmos::SolarSystem.new :name => 'nsys2',
                                     :location => Motel::Location.new(:id => '2002', :x => 0, :y => 0, :z => 0)
    @jg1   = Cosmos::JumpGate.new    :solar_system => @sys1, :endpoint => @sys2,
                                     :location => Motel::Location.new(:id =>  2003,  :x => 110, :y => -100, :z => -100)
    @ast1  = Cosmos::Asteroid.new    :name => 'asteroid1',
                                     :location => Motel::Location.new(:id =>  2004,  :x => 110, :y => -100, :z => -100)

    @resource = Cosmos::Resource.new :type => 'gem', :name => 'diamond'

    @gal1.add_child(@sys1)
    @gal1.add_child(@sys2)
    @sys1.add_child(@jg1)
    @sys1.add_child(@ast1)

    Motel::Runner.instance.run @gal1.location
    Motel::Runner.instance.run @sys1.location
    Motel::Runner.instance.run @sys2.location
    Motel::Runner.instance.run @jg1.location
    Motel::Runner.instance.run @ast1.location
    Cosmos::Registry.instance.add_child @gal1

    @rs1 = Cosmos::Registry.instance.set_resource @ast1.name, @resource, 50

    TestUser.add_privilege('view', 'cosmos_entities')

    ############## test manu
    @ship1  = Manufactured::Ship.new    :id => 'nship1', :user_id => 'user1', :type => :corvette,
                                        :location => Motel::Location.new(:id => '2005', :x => -100, :y => -100, :z => -100)
    @ship2  = Manufactured::Ship.new    :id => 'nship2', :user_id => @testuser2.id, :solar_system => @sys, :type => :mining,
                                        :location => Motel::Location.new(:id => '2006', :x => -101, :y => -101, :z => -101)
    @stat1  = Manufactured::Station.new :id => 'nstation1', :user_id => 'user1', :type => :manufacturing,
                                        :location => Motel::Location.new(:id => '2007', :x => -102, :y => -102, :z => -102)
    @stat2  = Manufactured::Station.new :id => 'nstation2', :user_id => 'user1',
                                        :location => Motel::Location.new(:id => '2008', :x => -103, :y => -103, :z => -103)
    @fleet1 = Manufactured::Fleet.new   :id => 'nfleet1', :user_id => 'user1'

    @ship1.parent = @ship2.parent = @stat1.parent = @stat2.parent = @sys1
    @ship1.location.parent = @ship2.location.parent = @stat1.location.parent = @stat2.location.parent = @sys1.location

    ############## test motel
    @new_loc1 = Motel::Location.new(:id => 2004, :parent_id => @sys1.location.id, :x => -105, :y => -100, :z => -100)
    @new_loc2 = Motel::Location.new(:id => 2004, :parent_id => @sys2.location.id, :x => -125, :y => -100, :z => -100)
  end

  after(:each) do
    Manufactured::Registry.instance.terminate
    FileUtils.rm_f '/tmp/manufactured-test' if File.exists?('/tmp/manufactured-test')
  end

  it "should permit users with create manufactured_entities to create_entity" do
    Cosmos::Registry.instance.init
    Manufactured::Registry.instance.init

    oldl = Motel::Runner.instance.locations.size

    # invalid type
    lambda {
      Omega::Client::Node.invoke_request('manufactured::create_entity', 1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)


    # valid data, no permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::create_entity', @ship1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    Motel::Runner.instance.locations.size.should == oldl

    TestUser.add_privilege('create', 'manufactured_entities')

    # parent system not found
    lambda{
      Omega::Client::Node.invoke_request('manufactured::create_entity', @ship1)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    Motel::Runner.instance.locations.size.should == oldl

    Cosmos::Registry.instance.add_child @gal1

    # valid call
    lambda{
      ship1 = Omega::Client::Node.invoke_request('manufactured::create_entity', @ship1)
      stat1 = Omega::Client::Node.invoke_request('manufactured::create_entity', @stat1)
      stat2 = Omega::Client::Node.invoke_request('manufactured::create_entity', @stat2)
      fleet = Omega::Client::Node.invoke_request('manufactured::create_entity', @fleet1)

      ship1.class.should == Manufactured::Ship
      ship1.id.should == @ship1.id
      stat1.class.should == Manufactured::Station
      stat1.id.should == @stat1.id
      stat2.class.should == Manufactured::Station
      stat2.id.should == @stat2.id
      fleet.class.should == Manufactured::Fleet
      fleet == @fleet1.id
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should    == 1
    Manufactured::Registry.instance.stations.size.should == 2
    Manufactured::Registry.instance.fleets.size.should   == 1

    Motel::Runner.instance.locations.size.should == oldl + 3 # locations created for ships, stations

    # verify owner & role has view / modify permissions on entity
    [@u1, @ur1].each { |u|
      u.privileges.find { |p| p.id == 'view'   && p.entity_id == 'manufactured_entity-' + @ship1.id  }.should_not be_nil
      u.privileges.find { |p| p.id == 'view'   && p.entity_id == 'manufactured_entity-' + @stat1.id  }.should_not be_nil
      u.privileges.find { |p| p.id == 'view'   && p.entity_id == 'manufactured_entity-' + @stat2.id  }.should_not be_nil
      u.privileges.find { |p| p.id == 'view'   && p.entity_id == 'manufactured_entity-' + @fleet1.id }.should_not be_nil
      u.privileges.find { |p| p.id == 'view'   && p.entity_id == 'location-' + @ship1.location.id }.should_not be_nil
      u.privileges.find { |p| p.id == 'view'   && p.entity_id == 'location-' + @stat1.location.id }.should_not be_nil
      u.privileges.find { |p| p.id == 'view'   && p.entity_id == 'location-' + @stat2.location.id }.should_not be_nil
      u.privileges.find { |p| p.id == 'modify' && p.entity_id == 'manufactured_entity-' + @ship1.id  }.should_not be_nil
      u.privileges.find { |p| p.id == 'modify' && p.entity_id == 'manufactured_entity-' + @stat1.id  }.should_not be_nil
      u.privileges.find { |p| p.id == 'modify' && p.entity_id == 'manufactured_entity-' + @stat2.id  }.should_not be_nil
      u.privileges.find { |p| p.id == 'modify' && p.entity_id == 'manufactured_entity-' + @fleet1.id }.should_not be_nil
    }

    (Manufactured::Registry.instance.ships + Manufactured::Registry.instance.stations).each { |e|
      Motel::Runner.instance.locations.collect { |l| l.id }.include?(e.location.id).should be_true
      e.location.parent_id.should == @sys1.location.id
      e.location.parent.id.should == @sys1.location.id

      @u1.privileges.find { |p| p.id == 'view'   && p.entity_id == 'location-' + e.location.id }.should_not be_nil
    }
  end

  it "should verify entity ids are unique when creating entities" do
    TestUser.add_privilege('create', 'manufactured_entities')

    olds = Manufactured::Registry.instance.ships.size

    # valid request
    lambda{
      Omega::Client::Node.invoke_request('manufactured::create_entity', @ship1)
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should    == olds + 1

    # id already taken
    lambda{
      Omega::Client::Node.invoke_request('manufactured::create_entity', @ship1)
    #}.should raise_error(ArgumentError)
    }.should raise_error

    Manufactured::Registry.instance.ships.size.should    == olds + 1
  end

  it "should permit users with create manufactured_entities to construct_entity" do
    Manufactured::Registry.instance.init
    Manufactured::Registry.instance.create @stat1

    oldsh = Manufactured::Registry.instance.ships.size
    oldl  = Motel::Runner.instance.locations.size

    # non-existant system
    lambda{
      Omega::Client::Node.invoke_request('manufactured::construct_entity', 'non_existant', 'Manufactured::Ship')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # not enough permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::construct_entity', @stat1, 'Manufactured::Ship')
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('create', 'manufactured_entities')

    # station does not have enough resources
    lambda{
      Omega::Client::Node.invoke_request('manufactured::construct_entity', @stat1, 'Manufactured::Ship')
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    @stat1.add_resource('metal-alloy', 5000)

    @stat1.type = :offense

    # station is of the wrong type
    lambda{
      Omega::Client::Node.invoke_request('manufactured::construct_entity', @stat1, 'Manufactured::Ship')
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    @stat1.type = :manufacturing


    # valid call
    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::construct_entity', @stat1.id, 'Manufactured::Ship', 'type', 'battlecruiser')
      rship.class.should == Manufactured::Ship
      rship.parent.name.should == @sys1.name
      rship.location.should_not be_nil
      rship.type.should == :battlecruiser
      rship.size.should == Manufactured::Ship::SHIP_SIZES[:battlecruiser]
      rship.user_id = TestUser.id
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should == oldsh + 1
    Motel::Runner.instance.locations.size.should      == oldl  + 1
  end

  it "should only accept valid params to instantiate manufactured_entities with when invoking construct_entity" do
    Manufactured::Registry.instance.init
    Manufactured::Registry.instance.create @stat1

    TestUser.add_privilege('create', 'manufactured_entities')
    @stat1.add_resource('metal-alloy', 5000)

    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::construct_entity', @stat1.id, 'Manufactured::Ship')
      rship.should_not be_nil
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should == 1

    # verify defaults
    Manufactured::Registry.instance.ships[0].type.should == :frigate
    Manufactured::Registry.instance.ships[0].size.should == Manufactured::Ship::SHIP_SIZES[:frigate]
    (@stat1.location - Manufactured::Registry.instance.ships[0].location).should == @stat1.construction_distance

    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::construct_entity', @stat1.id, 'Manufactured::Ship', 'type', 'transport', 'size', 5110)
      rship.should_not be_nil
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should == 2

    # verify set params
    Manufactured::Registry.instance.ships[1].type.should == :transport
    Manufactured::Registry.instance.ships[1].size.should == Manufactured::Ship::SHIP_SIZES[:transport]
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to get_entity" do
    Motel::Runner.instance.run @ship1.location
    Manufactured::Registry.instance.create @ship1

    # invalid id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::get_entity', 'with_id', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # no permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::get_entity', 'with_id', @ship1.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('view', 'manufactured_entities')

    # invalid qualifier
    lambda{
      Omega::Client::Node.invoke_request('manufactured::get_entity', 'without_id', @ship1.id)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid request
    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::get_entity', 'with_id', @ship1.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == @ship1.id
    }.should_not raise_error

    TestUser.clear_privileges.add_privilege('view', 'manufactured_entity-' + @ship1.id.to_s)

    # valid request
    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::get_entity', 'with_id', @ship1.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == @ship1.id
    }.should_not raise_error

    @ship1.location.parent.should == @sys1.location
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to get_entities from_location" do
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @stat1.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @stat1

    # invalid location
    lambda{
      Omega::Client::Node.invoke_request('manufactured::get_entity', 'of_type', 'Manufactured::Ship', 'with_location', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # type / location mismatch
    lambda{
      Omega::Client::Node.invoke_request('manufactured::get_entity', 'of_type', 'Manufactured::Ship', 'with_location', @stat1.location.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # not enought permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::get_entity', 'of_type', 'Manufactured::Ship', 'with_location', @ship1.location.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('view', 'manufactured_entities')

    # valid request
    lambda{
      entity = Omega::Client::Node.invoke_request('manufactured::get_entity', 'of_type', 'Manufactured::Ship', 'with_location', @ship1.location.id)
      entity.class.should == Manufactured::Ship
      entity.id.should == @ship1.id
    }.should_not raise_error

    # valid request
    lambda{
      entity = Omega::Client::Node.invoke_request('manufactured::get_entity', 'of_type', 'Manufactured::Station', 'with_location', @stat1.location.id)
      entity.class.should == Manufactured::Station
      entity.id.should == @stat1.id
    }.should_not raise_error
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to get_entities under" do
    Motel::Runner.instance.run @ship1.location
    Manufactured::Registry.instance.create @ship1

    # invalid id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::get_entities', 'under', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      entities = Omega::Client::Node.invoke_request('manufactured::get_entities', 'under', @sys1.id)
      entities.class.should == Array
      entities.size.should == 0
    }.should_not raise_error

    TestUser.add_privilege('view', 'manufactured_entities')

    # valid request
    lambda{
      entities = Omega::Client::Node.invoke_request('manufactured::get_entities', 'under', @sys1.id)
      entities.class.should == Array
      entities.size.should == 1
      entities.first.class.should == Manufactured::Ship
      entities.first.id.should == @ship1.id
      # TODO verify entities.first.location is latest tracked by motel
    }.should_not raise_error

    TestUser.clear_privileges.add_privilege('view', 'manufactured_entity-' + @ship1.id.to_s)

    # valid request
    lambda{
      entities = Omega::Client::Node.invoke_request('manufactured::get_entities', 'under', @sys1.id)
      entities.class.should == Array
      entities.size.should == 1
      entities.first.class.should == Manufactured::Ship
      entities.first.id.should == @ship1.id
    }.should_not raise_error
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to get_entities for_user" do
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @ship2.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @ship2

    # invalid user id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::get_entities', 'owned_by', 'non_existant', 'of_type', 'Manufactured::Ship')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # valid request, no matching data
    lambda{
      entities = Omega::Client::Node.invoke_request('manufactured::get_entities', 'owned_by', @testuser2.id, 'of_type', 'Manufactured::Ship')
      entities.class.should == Array
      entities.size.should == 0
    }.should_not raise_error

    TestUser.add_privilege('view', 'manufactured_entities')

    # valid request
    lambda{
      entities = Omega::Client::Node.invoke_request('manufactured::get_entities', 'owned_by', @testuser2.id, 'of_type', 'Manufactured::Ship')
      entities.class.should == Array
      entities.size.should == 1
      entities.first.class.should == Manufactured::Ship
      entities.first.id.should == @ship2.id
    }.should_not raise_error

    TestUser.clear_privileges.add_privilege('view', 'manufactured_entity-' + @ship2.id.to_s)

    # valid request
    lambda{
      entities = Omega::Client::Node.invoke_request('manufactured::get_entities', 'owned_by', @testuser2.id, 'of_type', 'Manufactured::Ship')
      entities.class.should == Array
      entities.size.should == 1
      entities.first.class.should == Manufactured::Ship
      entities.first.id.should == @ship2.id
    }.should_not raise_error
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to subscribe to events" do
    u = TestUser.add_privilege('view', 'manufactured_entities')

    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @ship2
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @ship2.location
    @ship2 = Manufactured::Registry.instance.ships.find { |s| s.id == 'nship2' }

    received_events, received_attackers, received_defenders = [],[],[]
    RJR::Dispatcher.add_handler('manufactured::event_occurred') { |*args|
      received_events << args[0]
      received_attackers << args[1]
      received_defenders << args[2]
    }

    lambda{
      Omega::Client::Node.invoke_request('manufactured::subscribe_to', 'nonexistant', 'defended')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    @ship2.notification_callbacks.size.should == 0

    lambda{
      rs = Omega::Client::Node.invoke_request('manufactured::subscribe_to', @ship2.id, 'defended')
      rs.class.should == Manufactured::Ship
      rs.id.should == @ship2.id
    }.should_not raise_error

    @ship2.notification_callbacks.size.should == 1
    @ship2.notification_callbacks.first.endpoint_id.should == Omega::Client::Node.message_headers['source_node']

    lambda{
      rs = Omega::Client::Node.invoke_request('manufactured::subscribe_to', @ship2.id, 'attacked')
      rs.class.should == Manufactured::Ship
      rs.id.should == @ship2.id
    }.should_not raise_error

    @ship2.notification_callbacks.size.should == 2

    # ensure duplicate events are overwritten
    lambda{
      rs = Omega::Client::Node.invoke_request('manufactured::subscribe_to', @ship2.id, 'attacked')
      rs.class.should == Manufactured::Ship
      rs.id.should == @ship2.id
    }.should_not raise_error

    @ship2.notification_callbacks.size.should == 2

    TestUser.add_privilege('modify', 'manufactured_entity-' + @ship1.id)
    Omega::Client::Node.invoke_request('manufactured::attack_entity', @ship1.id, @ship2.id)
    sleep 1
    received_events.size.should > 0
    received_events.first.should == 'defended'

    # verify when user no longer has access to entity, callbacks are discontinued
    TestUser.clear_privileges
    sleep 2
    @ship2.notification_callbacks.size.should == 1
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to remove callbacks" do
    u = TestUser.add_privilege('view', 'manufactured_entities').
                 add_privilege('modify', 'manufactured_entities')

    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @ship2.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @ship2

    received_events, received_attackers, received_defenders = [],[],[]
    RJR::Dispatcher.add_handler('manufactured::event_occurred') { |*args|
      received_events << args[0]
      received_attackers << args[1]
      received_defenders << args[2]
    }

    lambda{
      rloc = Omega::Client::Node.invoke_request('manufactured::subscribe_to', @ship2.id, 'defended')
      rloc.class.should == Manufactured::Ship
      rloc.id.should == @ship2.id
    }.should_not raise_error

    @ship2.notification_callbacks.size.should == 1

    TestUser.clear_privileges

    lambda{
      rs = Omega::Client::Node.invoke_request('manufactured::remove_callbacks', @ship2.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('view', 'manufactured_entities').
             add_privilege('modify', 'manufactured_entities')

    lambda{
      rs = Omega::Client::Node.invoke_request('manufactured::remove_callbacks', @ship2.id)
      rs.class.should == Manufactured::Ship
      rs.id.should == @ship2.id
    }.should_not raise_error

    @ship2.notification_callbacks.size.should == 0
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to move_entity within a system" do
    Motel::Runner.instance.run @ship1.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @stat1

    # invalid ship id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', 'non_existant', @new_loc1)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    @new_loc1.parent_id = 'non_existant'

    # invalid destination
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    @new_loc1.parent_id = @sys1.id

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'manufactured_entities')

    # cannot specify fleet
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', fl1.id, @new_loc1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    @new_loc1.parent_id = @gal1.name

    # invalid destination (galaxy)
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    @new_loc1.parent_id = @sys1.location.id

    # invalid destination (not a location)
    lambda {
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, 5)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid destination (same coordinates as ship)
    lambda {
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @ship1.location)
    #}.should raise_error(OperationError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
      rship.class.should == Manufactured::Ship
      rship.id.should == @ship1.id
    }.should_not raise_error

    # verify ship is now moving using a linear movement strategy towards new location
    rloc = Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Linear
    rloc.movement_strategy.direction_vector_x.should == -1
    rloc.movement_strategy.direction_vector_y.should == 0
    rloc.movement_strategy.direction_vector_z.should == 0
    rloc.movement_callbacks.size.should == 1

    sleep 2

    # verify ship has arrived and is no longer moving
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Stopped
    rloc.movement_callbacks.size.should == 0
    (rloc.x - @new_loc1.x).should < 25 # FIXME since the entity is moved in increments of speed, might not be exactly on
    rloc.y.should == @new_loc1.y
    rloc.z.should == @new_loc1.z

    rship = Manufactured::Registry.instance.find(:id => @ship1.id)
    rship.first.location.x.should == rloc.x
    rship.first.location.y.should == rloc.y
    rship.first.location.z.should == rloc.z
  end



  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to move_entity between systems" do
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @stat1.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @stat1

    @ship1.location.movement_callbacks << Motel::Callbacks::Movement.new(:endpoint => Manufactured::RJRAdapter.send(:class_variable_get, :@@local_node).node_id)

    # invalid ship id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', 'non_existant', @new_loc1)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    @new_loc1.parent_id = 'non_existant'

    # invalid destination id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    @new_loc1.parent_id = @sys2.location.id

    # insufficent permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'manufactured_entities')

    @new_loc1.parent_id = @gal1.name

    # invalid destination (galaxy)
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    @new_loc1.parent_id = @sys2.location.id

    # not within activation distance of gate
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
    #}.should raise_error(OperationError)
    }.should raise_error(Exception)

    Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }.x = 100

    # valid call
    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
      rship.class.should == Manufactured::Ship
      rship.id.should == @ship1.id
      rship.parent.name.should == @sys2.name
    }.should_not raise_error

    # valid call
    lambda{
      rstat = Omega::Client::Node.invoke_request('manufactured::move_entity', @stat1.id, @new_loc1)
      rstat.class.should == Manufactured::Station
      rstat.id.should == @stat1.id
      rstat.parent.name.should == @sys2.name
    }.should_not raise_error

    # verify ship is now in the new system
    rloc = Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Stopped
    rloc.parent_id.should == @sys2.location.id
    rloc.movement_callbacks.size.should == 0
    rloc.proximity_callbacks.size.should == 0

    # verify station is now in the new system
    rloc = Motel::Runner.instance.locations.find { |l| l.id == @stat1.location.id }
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Stopped
    rloc.parent_id.should == @sys2.location.id
  end

  it "should not allow a docked ship to move within on inbetween systems" do
    TestUser.add_privilege('modify', 'manufactured_entities')
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @stat1.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @stat1
    @ship1.dock_at(@stat1)

    # ship is docked, cannot move in system
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
    #}.should raise_error(OperationError)
    }.should raise_error(Exception)

    # ship is docked, cannot move inbetween systems
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc2)
    #}.should raise_error(OperationError)
    }.should raise_error(Exception)

    # verify ship is not moving & in orig system
    rloc = Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Stopped
    rloc.parent.id.should == @sys1.location.id

    @ship1.undock

    # valid call
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc1)
    }.should_not raise_error

    # verify ship is moving in orig system
    rloc = Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Linear
    rloc.parent.id.should == @sys1.location.id

    Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }.x = 100

    # valid call
    lambda{
      Omega::Client::Node.invoke_request('manufactured::move_entity', @ship1.id, @new_loc2)
    }.should_not raise_error

    # verify ship is in new system
    rloc = Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Stopped
    rloc.parent.id.should == @sys2.location.id
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to follow_entity" do
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @ship2.location
    Motel::Runner.instance.run @stat1.location
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @ship2
    Manufactured::Registry.instance.create @stat1

    # cannot specify the same entity and target
    lambda{
      Omega::Client::Node.invoke_request('manufactured::follow_entity', @ship1.id, @ship1.id, 10)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid ship id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::follow_entity', 'non_existant', @ship2.id, 10)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid target id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::follow_entity', @ship1.id, 'non_existant', 10)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid distance
    lambda{
      Omega::Client::Node.invoke_request('manufactured::follow_entity', @ship1.id, @ship2.id, -10)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::follow_entity', @ship1.id, @ship2.id, 10)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'manufactured_entities')
    TestUser.add_privilege('view', 'manufactured_entities')

    # cannot follow with station
    lambda{
      Omega::Client::Node.invoke_request('manufactured::follow_entity', @stat1.id, @ship2.id, 10)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # cannot follow station
    lambda{
      Omega::Client::Node.invoke_request('manufactured::follow_entity', @ship1.id, @stat1.id, 10)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # entities not in the same system
    @ship1.parent = @sys2
    lambda{
      Omega::Client::Node.invoke_request('manufactured::follow_entity', @ship1.id, @ship2.id, 10)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)
    @ship1.parent = @sys1

    # entity is docked
    @ship1.dock_at(@stat1)
    lambda{
      Omega::Client::Node.invoke_request('manufactured::follow_entity', @ship1.id, @ship2.id, 10)
    #}.should raise_error(OperationError)
    }.should raise_error(Exception)
    @ship1.undock

    # valid call
    lambda{
      entity = Omega::Client::Node.invoke_request('manufactured::follow_entity', @ship1.id, @ship2.id, 10)
      entity.class.should == Manufactured::Ship
      entity.id.should == @ship1.id
    }.should_not raise_error

    @ship1.location.movement_strategy.class.should == Motel::MovementStrategies::Follow
    @ship1.location.movement_strategy.tracked_location_id.should == @ship2.location.id
    @ship1.location.movement_strategy.distance.should == 10
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to attack_entity" do
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @ship2
    Manufactured::Registry.instance.create @stat1
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @ship2.location
    Motel::Runner.instance.run @stat1.location
    Manufactured::Registry.instance.attack_commands.size.should == 0

    # attacker cannot be defender
    lambda{
      Omega::Client::Node.invoke_request('manufactured::attack_entity', @ship2.id, @ship2.id)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid attacker id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::attack_entity', 'non_existant', @ship2.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid defender id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::attack_entity', @ship1.id, 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid attacker (station)
    lambda{
      Omega::Client::Node.invoke_request('manufactured::attack_entity', @stat1.id, @ship2.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid defender (station)
    lambda{
      Omega::Client::Node.invoke_request('manufactured::attack_entity', @ship1.id, @stat1.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::attack_entity', @ship1.id, @ship2.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'manufactured_entities')
    TestUser.add_privilege('view',   'manufactured_entities')

    # ship doesn't have attack capabilities
    @ship1.type = :frigate
    lambda{
      Omega::Client::Node.invoke_request('manufactured::attack_entity', @ship1.id, @ship2.id)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)
    @ship1.type = :bomber

    # ships are too far away
    sloc =Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }
    sloc.x = 500
    lambda{
      Omega::Client::Node.invoke_request('manufactured::attack_entity', @ship1.id, @ship2.id)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)
    sloc.x = -100

    # ships are in different systems
    @ship1.solar_system = @sys2
    sloc.parent = @sys2.location
    lambda{
      Omega::Client::Node.invoke_request('manufactured::attack_entity', @ship1.id, @ship2.id)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)
    @ship1.solar_system = @sys1
    sloc.parent = @sys1.location

    # valid call
    lambda{
      ships = Omega::Client::Node.invoke_request('manufactured::attack_entity', @ship1.id, @ship2.id)
      ships.class.should == Array
      ships.size.should == 2
      ships.first.id.should == @ship1.id
      ships.last.id.should  == @ship2.id
    }.should_not raise_error

    Manufactured::Registry.instance.attack_commands.size.should == 1
    Manufactured::Registry.instance.attack_commands.first.last.hooks[:before].size.should == 1
    # TODO ensure locations are updated b4 attack cycle?
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to stop_entity" do
    @ship1.location.movement_strategy = Motel::MovementStrategies::Linear.new(:speed => 5)
    Motel::Runner.instance.run @ship1.location
    Manufactured::Registry.instance.create @ship1

    # invalid ship id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::stop_entity', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::stop_entity', @ship1.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'manufactured_entities')

    # cannot specify fleet
    lambda{
      Omega::Client::Node.invoke_request('manufactured::stop_entity', fl1.id)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::stop_entity', @ship1.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == @ship1.id
      rship.location.movement_strategy.class.should == Motel::MovementStrategies::Stopped
    }.should_not raise_error

    # verify ship location is now moving using the stopped movement strategy
    rloc = Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Stopped
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to start_mining" do
    Motel::Runner.instance.run @ship2.location
    Manufactured::Registry.instance.create @ship2
    Manufactured::Registry.instance.mining_commands.size.should == 0

    # invalid entity id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::start_mining', @ship2.id, 'non_existant', @resource.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid resource id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::start_mining', @ship2.id, @ast1.name, 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid ship id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::start_mining', 'non_existant', @ast1.name, @resource.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::start_mining', @ship2.id, @ast1.name, @resource.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'manufactured_entities')

    # ship cannot mine resource
    rloc = Motel::Runner.instance.locations.find { |l| l.id == @ship2.location.id }
    rloc.x = 5000
    lambda{
      Omega::Client::Node.invoke_request('manufactured::start_mining', @ship2.id, @ast1.name, @resource.id)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)
    rloc.x = 100

    # valid call
    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::start_mining', @ship2.id, @ast1.name, @resource.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == @ship2.id
      rship.notification_callbacks.size.should == 2
      rship.notification_callbacks.first.type.should == :resource_collected
      rship.notification_callbacks.first.endpoint_id.should == Manufactured::RJRAdapter.send(:class_variable_get, :@@local_node).message_headers['source_node']
      rship.notification_callbacks.last.type.should == :mining_stopped
      rship.notification_callbacks.last.endpoint_id.should == Manufactured::RJRAdapter.send(:class_variable_get, :@@local_node).message_headers['source_node']
    }.should_not raise_error

    Manufactured::Registry.instance.mining_commands.size.should == 1
    Manufactured::Registry.instance.mining_commands.first.last.hooks[:before].size.should == 1
    # TODO ensure locations are updated b4 attack cycle?
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to transfer_resource" do
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @stat1
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @stat1.location

    @ship1.add_resource @resource.id, 50

    # invalid quantity
    lambda{
      Omega::Client::Node.invoke_request('manufactured::transfer_resource', @ship1.id, @stat1.id, @resource.id, -10)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid from_entity id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::transfer_resource', 'non_existant', @stat1.id, @resource.id, 10)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid to_entity id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::transfer_resource', @ship1.id, 'non_existant', @resource.id, 10)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::transfer_resource', @ship1.id, @stat1.id, @resource.id, 10)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'manufactured_entity-' + @ship1.id)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::transfer_resource', @ship1.id, @stat1.id, @resource.id, 10)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'manufactured_entity-' + @stat1.id)

    nres = Cosmos::Resource.new :type => 'gem', :name => 'ruby'

    # invalid resource
    lambda{
      Omega::Client::Node.invoke_request('manufactured::transfer_resource', @ship1.id, @stat1.id, nres.id, 10)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)

    # too large quantity
    lambda{
      Omega::Client::Node.invoke_request('manufactured::transfer_resource', @ship1.id, @stat1.id, @resource.id, 1000)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      ret = Omega::Client::Node.invoke_request('manufactured::transfer_resource', @ship1.id, @stat1.id, @resource.id, 10)
      ret.class.should == Array
      ret.size.should == 2
      ret.first.id.should == @ship1.id
      ret.last.id.should  == @stat1.id
    }.should_not raise_error

    @ship1.resources[@resource.id].should == 40
    @stat1.resources[@resource.id].should == 10

    # valid call
    lambda{
      ret = Omega::Client::Node.invoke_request('manufactured::transfer_resource', @stat1.id, @ship1.id, @resource.id, 5)
      ret.class.should == Array
      ret.size.should == 2
      ret.first.id.should == @stat1.id
      ret.last.id.should  == @ship1.id
    }.should_not raise_error

    @ship1.resources[@resource.id].should == 45
    @stat1.resources[@resource.id].should == 5
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to dock/undock to stations" do
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @stat1
    Motel::Runner.instance.run @ship1.location
    Motel::Runner.instance.run @stat1.location

    # invalid ship id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::dock', 'non_existant', @stat1.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid station id
    lambda{
      Omega::Client::Node.invoke_request('manufactured::dock', @ship1.id, 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('manufactured::dock', @ship1.id, @stat1.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'manufactured_entities')

    # not dockable
    rloc = Motel::Runner.instance.locations.find { |l| l.id == @ship1.location.id }
    rloc.x = 1000
    lambda{
      Omega::Client::Node.invoke_request('manufactured::dock', @ship1.id, @stat1.id)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)
    rloc.x = -100

    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::dock', @ship1.id, @stat1.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == @ship1.id
      rship.docked?.should be_true
      rship.docked_at.id.should == @stat1.id
    }.should_not raise_error

    @ship1.docked?.should be_true
    @ship1.docked_at.id.should == @stat1.id
    @ship1.location.movement_strategy.should == Motel::MovementStrategies::Stopped.instance

    lambda{
      rship = Omega::Client::Node.invoke_request('manufactured::undock', @ship1.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == @ship1.id
      rship.docked?.should be_false
      rship.docked_at.should be_nil
    }.should_not raise_error

    @ship1.docked?.should be_false
    @ship1.docked_at.should be_nil

    # ship is not docked at station, undock is no longer a valid operation
    lambda{
      Omega::Client::Node.invoke_request('manufactured::undock', @ship1.id)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)
  end

  it "should permit local nodes to save and restore state" do
    Manufactured::Registry.instance.create @ship1
    Manufactured::Registry.instance.create @stat1
    Manufactured::Registry.instance.create @stat2
    oldsh = Manufactured::Registry.instance.ships.size
    oldst = Manufactured::Registry.instance.stations.size

    lambda{
      ret = Omega::Client::Node.invoke_request('manufactured::save_state', '/tmp/manufactured-test')
      ret.should be_nil
    }.should_not raise_error

    Manufactured::Registry.instance.init
    Manufactured::Registry.instance.ships.size.should == 0
    Manufactured::Registry.instance.stations.size.should == 0

    lambda{
      ret = Omega::Client::Node.invoke_request('manufactured::restore_state', '/tmp/manufactured-test')
      ret.should be_nil
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should == oldsh
    Manufactured::Registry.instance.stations.size.should == oldst
    Manufactured::Registry.instance.ships.find    { |sh| sh.id == @ship1.id }.should_not be_nil
    Manufactured::Registry.instance.stations.find { |st| st.id == @stat1.id }.should_not be_nil
    Manufactured::Registry.instance.stations.find { |st| st.id == @stat1.id }.should_not be_nil
  end
end
