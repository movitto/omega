# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'
require 'rjr/local_node'

describe Motel::RJRAdapter do

  before(:all) do
    Motel::RJRAdapter.init
    @local_node = RJR::LocalNode.new :node_id => 'omega-test'
  end

  before(:each) do
    Motel::Runner.instance.clear
  end

  after(:all) do
    Motel::Runner.instance.stop
  end

  it "should raise exception if trying to find location that cannot be found" do
    Motel::Runner.instance.clear
    lambda{
      @local_node.invoke_request('motel::get_location', 'with_id', 'foobar')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)
  end

  it "should permit users with view location or view location-<id> to get_location" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_view => true
    u = TestUser.create.clear_privileges

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1

    lambda{
      @local_node.invoke_request('motel::get_location', 'with_id', loc1.id)
    #}.should raise_error(Omega::PermissionError, "session not found")
    }.should raise_error(Exception, "session not found")

    u.login(@local_node)

    lambda{
      @local_node.invoke_request('motel::get_location', 'with_id', loc1.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('view', 'locations')

    lambda{
      rloc = @local_node.invoke_request('motel::get_location', 'with_id', loc1.id)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    u.clear_privileges.add_privilege('view', 'location-' + loc1.id.to_s)

    lambda{
      rloc = @local_node.invoke_request('motel::get_location', 'with_id', loc1.id)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error
  end

  it "should permit any user to get location that does not restrict view" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_view => false
    u = TestUser.create.login(@local_node).clear_privileges

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1

    lambda{
      rloc = @local_node.invoke_request('motel::get_location', 'with_id', loc1.id)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error
  end

  it "should permit users view view locations to get locations within proximity of specified location" do
    loc0 = Motel::Location.new :id => 41, :x => 0,  :y => 0, :z => 0, :movement_strategy => TestMovementStrategy.new
    loc1 = Motel::Location.new :id => 42, :x => 0,  :y => 0, :z => 0, :parent_id => loc0.id, :movement_strategy => TestMovementStrategy.new
    loc2 = Motel::Location.new :id => 43, :x => 10, :y => 0, :z => 0, :parent_id => loc0.id, :movement_strategy => TestMovementStrategy.new
    loc3 = Motel::Location.new :id => 44, :x => 5,  :y => 0, :z => 0, :parent_id => loc0.id, :movement_strategy => TestMovementStrategy.new
    loc4 = Motel::Location.new :id => 44, :x => 5,  :y => 0, :z => 0, :parent_id => loc3.id, :movement_strategy => TestMovementStrategy.new
    u = TestUser.create.login(@local_node).clear_privileges

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc0
    Motel::Runner.instance.run loc2
    Motel::Runner.instance.run loc3
    Motel::Runner.instance.run loc4

    locations = @local_node.invoke_request('motel::get_locations', 'within', 7, 'of', loc1)
    locations.class.should == Array
    locations.size.should == 0

    u.add_privilege('view', 'locations')

    # invalid distance
    lambda{
      @local_node.invoke_request('motel::get_locations', 'within', -7, 'of', loc1)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)

    # invalid location
    lambda{
      @local_node.invoke_request('motel::get_locations', 'within', -7, 'of', "loc1")
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)

    locations = @local_node.invoke_request('motel::get_locations', 'within', 7, 'of', loc1)
    locations.class.should == Array
    locations.size.should == 1
    locations.first.id.should == loc3.id # only loc3 shares same parent and is close enough
  end

  it "should permit users with create locations to create_location" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new
    u = TestUser.create.clear_privileges

    Motel::Runner.instance.clear

    Motel::Runner.instance.locations.size.should == 0

    # not logged in
    lambda{
      @local_node.invoke_request('motel::create_location', loc1)
    #}.should raise_error(Omega::PermissionError, "session not found")
    }.should raise_error(Exception, "session not found")

    u.login(@local_node)

    # insufficient permissions
    lambda{
      @local_node.invoke_request('motel::create_location', loc1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('create', 'locations')

    # not a location
    lambda{
      rloc = @local_node.invoke_request('motel::create_location', "loc1")
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      rloc = @local_node.invoke_request('motel::create_location', loc1)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    Motel::Runner.instance.locations.size.should == 1
  end

  it "should validate and initialize new locations" do
    loc1 = Motel::Location.new :id => 42, :x => 50, :children => [123], :movement_strategy => TestMovementStrategy.new
    u = TestUser.create.login(@local_node).clear_privileges.add_privilege('create', 'locations')

    loc2 = Motel::Location.new :id => 43, :y => '50', :movement_callbacks => [Motel::Callbacks::Movement.new], :movement_strategy => 'invalid'
    loc1.parent_id = loc2.id

    lambda{
      rloc2 = @local_node.invoke_request('motel::create_location', loc2)
      rloc1 = @local_node.invoke_request('motel::create_location', loc1)
      rloc1.class.should == Motel::Location
      rloc2.class.should == Motel::Location
      rloc1.id.should == loc1.id
      rloc2.id.should == loc2.id
    }.should_not raise_error

    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }
    rloc2 = Motel::Runner.instance.locations.find { |l| l.id == 43 }

    rloc1.x.should == 50
    rloc1.y.should == 0
    rloc1.z.should == 0
    rloc2.x.should == 0
    rloc2.y.should == 50
    rloc2.z.should == 0

    rloc1.children.size.should == 0
    rloc2.movement_callbacks.size.should == 0
    rloc2.movement_strategy.should == Motel::MovementStrategies::Stopped.instance
  end

  it "should permit users with modify locations or modify location-<id> to update_location" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_modify => true
    u = TestUser.create.clear_privileges

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1

    loc1.x = 50

    lambda{
      @local_node.invoke_request('motel::update_location', loc1)
    #}.should raise_error(Omega::PermissionError, "session not found")
    }.should raise_error(Exception, "session not found")

    u.login(@local_node)

    lambda{
      @local_node.invoke_request('motel::update_location', loc1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'locations')

    lambda{
      rloc1 = @local_node.invoke_request('motel::update_location', loc1)
      rloc1.class.should == Motel::Location
      rloc1.id.should == loc1.id
    }.should_not raise_error

    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }
    rloc1.x.should == 50

    loc1.x = 70
    u.clear_privileges.add_privilege('modify', 'location-' + loc1.id.to_s)
    lambda{
      rloc1 = @local_node.invoke_request('motel::update_location', loc1)
      rloc1.class.should == Motel::Location
      rloc1.id.should == loc1.id
    }.should_not raise_error

    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }
    rloc1.x.should == 70
  end

  it "should validate and initialize locations to be updated" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :parent_id => 'nonexistant'
    u = TestUser.create.login(@local_node).clear_privileges.add_privilege('modify', 'locations')

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1

    lambda{
      rloc1 = @local_node.invoke_request('motel::update_location', loc1)
      rloc1.class.should == Motel::Location
      rloc1.id.should == loc1.id
    }.should_not raise_error
  end

  it "should permit any user to update_location that does not restrict modify" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_modify => false
    u = TestUser.create.login(@local_node).clear_privileges

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1

    loc1.x = 50

    lambda{
      rloc1 = @local_node.invoke_request('motel::update_location', loc1)
      rloc1.class.should == Motel::Location
      rloc1.id.should == loc1.id
    }.should_not raise_error

    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }
    rloc1.x.should == 50
  end

  it "should permit users with view locations or view location-<id> to track movement of locations" do
    linear = Motel::MovementStrategies::Linear.new(:speed => 5,
                                                   :direction_vector_x => 1,
                                                   :direction_vector_y => 0,
                                                   :direction_vector_z => 0)
    loc1 = Motel::Location.new :id => 42, :x => 0, :y => 0, :z => 0,
                               :movement_strategy => linear,
                               :restrict_view => true
    u = TestUser.create.login(@local_node).clear_privileges.add_privilege('view', 'locations')

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1
    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }

    times_moved = 0
    RJR::Dispatcher.add_handler('motel::on_movement') { |nloc|
      nloc.id.should == loc1.id
      times_moved += 1
    }

    lambda{
      @local_node.invoke_request('motel::track_movement', 'nonexistant', 5)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    rloc1.movement_callbacks.size.should == 0

    lambda{
      rloc = @local_node.invoke_request('motel::track_movement', loc1.id, 5)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 1
    rloc1.movement_callbacks.first.min_distance.should == 5

    # ensure subsequent trackings are overwritten
    lambda{
      rloc = @local_node.invoke_request('motel::track_movement', loc1.id, 3)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 1
    rloc1.movement_callbacks.first.min_distance.should == 3

    sleep 2
    times_moved.should > 0

    # verify when user no longer has access to location, callbacks are discontinued
    u.clear_privileges
    sleep 2
    rloc1.movement_callbacks.size.should == 0
  end

  it "should permit users with view locations or view location-<id> to track proximity of locations" do
    linear = Motel::MovementStrategies::Linear.new(:speed => 1,
                                                   :direction_vector_x => 1,
                                                   :direction_vector_y => 0,
                                                   :direction_vector_z => 0)
    loc1 = Motel::Location.new :id => 42, :x => 0, :y => 0, :z => 0,
                               :movement_strategy => linear,
                               :restrict_view => true
    loc2 = Motel::Location.new :id => 43, :x => 5, :y => 0, :z => 0,
                               :movement_strategy => Motel::MovementStrategies::Stopped.instance,
                               :restrict_view => true
    u = TestUser.create.login(@local_node).clear_privileges.add_privilege('view', 'locations')

    proximity_notifications = 0
    RJR::Dispatcher.add_handler('motel::on_proximity') { |nloc1, nloc2|
      nloc1.id.should == loc1.id
      nloc2.id.should == loc2.id
      proximity_notifications += 1
    }

    lambda{
      @local_node.invoke_request('motel::track_proximity', loc1.id, 'nonexistant', 'proximity', 5)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    loc1.movement_callbacks.size.should == 0

    lambda{
      @local_node.invoke_request('motel::track_proximity', 'nonexistant', loc2.id, 'proximity', 5)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1
    Motel::Runner.instance.run loc2

    lambda{
      rlocs = @local_node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'proximity', 10)
      rlocs.class.should == Array
      rlocs.size.should == 2
      rlocs.first.class.should == Motel::Location
      rlocs.last.class.should == Motel::Location
      rlocs.first.id.should == loc1.id
      rlocs.last.id.should == loc2.id
    }.should_not raise_error

    loc1.proximity_callbacks.size.should == 1
    loc1.proximity_callbacks.first.max_distance.should == 10

    # ensure subsequent trackings are overwritten
    lambda{
      rlocs = @local_node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'proximity', 5)
      rlocs.class.should == Array
      rlocs.size.should == 2
      rlocs.first.class.should == Motel::Location
      rlocs.last.class.should == Motel::Location
      rlocs.first.id.should == loc1.id
      rlocs.last.id.should == loc2.id
    }.should_not raise_error

    loc1.proximity_callbacks.size.should == 1
    loc1.proximity_callbacks.first.max_distance.should == 5

    sleep 2
    proximity_notifications.should > 0

    u.clear_privileges
    sleep 2
    loc1.proximity_callbacks.size.should == 0
  end

  it "should permit user to remove registered callbacks" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => Motel::MovementStrategies::Stopped.instance
    loc2 = Motel::Location.new :id => 43, :movement_strategy => Motel::MovementStrategies::Linear.new
    u = TestUser.create.login(@local_node).clear_privileges.add_privilege('view', 'locations')

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1
    Motel::Runner.instance.run loc2
    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }

    lambda{
      @local_node.invoke_request('motel::track_movement',  loc1.id, 3)
      @local_node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'proximity', 3)
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 1
    rloc1.proximity_callbacks.size.should == 1

    lambda{
      @local_node.invoke_request('motel::remove_callbacks', 'nonexistant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    u.clear_privileges

    lambda{
      @local_node.invoke_request('motel::remove_callbacks', loc1.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    u.add_privilege('view', 'locations')

    lambda{
      rloc = @local_node.invoke_request('motel::remove_callbacks', loc1.id)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 0
    rloc1.proximity_callbacks.size.should == 0

    # TODO test remove_callbacks of a certain type
  end

  it "should permit local nodes to save and restore state" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_modify => false
    u = TestUser.create.login(@local_node).clear_privileges

    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1
    Motel::Runner.instance.locations.size.should == 1

    lambda{
      ret = @local_node.invoke_request('motel::save_state', '/tmp/motel-test')
      ret.should be_nil
    }.should_not raise_error

    Motel::Runner.instance.clear
    Motel::Runner.instance.locations.size.should == 0

    lambda{
      ret = @local_node.invoke_request('motel::restore_state', '/tmp/motel-test')
      ret.should be_nil
    }.should_not raise_error

    Motel::Runner.instance.locations.size.should == 1
    Motel::Runner.instance.locations.first.id.should == loc1.id

    FileUtils.rm_f '/tmp/motel-test'
  end
end
