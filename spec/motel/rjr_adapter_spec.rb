# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/local_node'

describe Motel::RJRAdapter do

  after(:each) do
    FileUtils.rm_f '/tmp/motel-test' if File.exists?('/tmp/motel-test')
  end

  it "should raise exception if trying to find location that cannot be found" do
    lambda{
      Omega::Client::Node.invoke_request('motel::get_location', 'with_id', 'foobar')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)
  end

  it "should permit users with view location or view location-<id> to get_location" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_view => true
    Motel::Runner.instance.run loc1

    #lambda{
    #  @local_node.invoke_request('motel::get_location', 'with_id', loc1.id)
    ##}.should raise_error(Omega::PermissionError, "session not found")
    #}.should raise_error(Exception, "session not found")

    #u.login(@local_node)

    lambda{
      Omega::Client::Node.invoke_request('motel::get_location', 'with_id', loc1.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('view', 'locations')

    lambda{
      rloc = Omega::Client::Node.invoke_request('motel::get_location', 'with_id', loc1.id)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    TestUser.clear_privileges.add_privilege('view', 'location-' + loc1.id.to_s)

    lambda{
      rloc = Omega::Client::Node.invoke_request('motel::get_location', 'with_id', loc1.id)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error
  end

  it "should permit any user to get location that does not restrict view" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_view => false
    Motel::Runner.instance.run loc1

    lambda{
      rloc = Omega::Client::Node.invoke_request('motel::get_location', 'with_id', loc1.id)
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

    Motel::Runner.instance.run loc0
    Motel::Runner.instance.run loc2
    Motel::Runner.instance.run loc3
    Motel::Runner.instance.run loc4

    locations = Omega::Client::Node.invoke_request('motel::get_locations', 'within', 7, 'of', loc1)
    locations.class.should == Array
    locations.size.should == 0

    TestUser.add_privilege('view', 'locations')

    # invalid distance
    lambda{
      Omega::Client::Node.invoke_request('motel::get_locations', 'within', -7, 'of', loc1)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)

    # invalid location
    lambda{
      Omega::Client::Node.invoke_request('motel::get_locations', 'within', -7, 'of', "loc1")
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)

    locations = Omega::Client::Node.invoke_request('motel::get_locations', 'within', 7, 'of', loc1)
    locations.class.should == Array
    locations.size.should == 1
    locations.first.id.should == loc3.id # only loc3 shares same parent and is close enough
  end

  it "should permit users with create locations to create_location" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new

    old = Motel::Runner.instance.locations.size

    # not logged in
    #lambda{
    #  @local_node.invoke_request('motel::create_location', loc1)
    ##}.should raise_error(Omega::PermissionError, "session not found")
    #}.should raise_error(Exception, "session not found")

    #u.login(@local_node)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('motel::create_location', loc1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('create', 'locations')

    # not a location
    lambda{
      rloc = Omega::Client::Node.invoke_request('motel::create_location', "loc1")
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      rloc = Omega::Client::Node.invoke_request('motel::create_location', loc1)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    Motel::Runner.instance.locations.size.should == old + 1
  end

  it "should validate and initialize new locations" do
    loc1 = Motel::Location.new :id => 42, :x => 50, :children => [123], :movement_strategy => TestMovementStrategy.new
    TestUser.add_privilege('create', 'locations')

    loc2 = Motel::Location.new :id => 43, :y => '50', :movement_callbacks => [Motel::Callbacks::Movement.new], :movement_strategy => 'invalid'
    loc1.parent_id = loc2.id

    lambda{
      rloc2 = Omega::Client::Node.invoke_request('motel::create_location', loc2)
      rloc1 = Omega::Client::Node.invoke_request('motel::create_location', loc1)
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

    Motel::Runner.instance.run loc1

    loc1.x = 50

    # not logged in
    #lambda{
    #  @local_node.invoke_request('motel::update_location', loc1)
    ##}.should raise_error(Omega::PermissionError, "session not found")
    #}.should raise_error(Exception, "session not found")

    #u.login(@local_node)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('motel::update_location', loc1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'locations')

    # invalid location
    lambda{
      Omega::Client::Node.invoke_request('motel::update_location', "loc1")
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid location id
    loc1.id = nil
    lambda{
      Omega::Client::Node.invoke_request('motel::update_location', loc1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)
    loc1.id = 42

    # invalid location id (doesn't exist)
    loc2 = Motel::Location.new :id => 43
    lambda{
      Omega::Client::Node.invoke_request('motel::update_location', loc2)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # valid call
    lambda{
      rloc1 = Omega::Client::Node.invoke_request('motel::update_location', loc1)
      rloc1.class.should == Motel::Location
      rloc1.id.should == loc1.id
    }.should_not raise_error

    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }
    rloc1.x.should == 50

    # valid call
    loc1.x = 70
    TestUser.clear_privileges.add_privilege('modify', 'location-' + loc1.id.to_s)
    lambda{
      rloc1 = Omega::Client::Node.invoke_request('motel::update_location', loc1)
      rloc1.class.should == Motel::Location
      rloc1.id.should == loc1.id
    }.should_not raise_error

    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }
    rloc1.x.should == 70
  end

  it "should validate and initialize locations to be updated" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :parent_id => 'nonexistant'
    TestUser.add_privilege('modify', 'locations')

    Motel::Runner.instance.run loc1

    lambda{
      rloc1 = Omega::Client::Node.invoke_request('motel::update_location', loc1)
      rloc1.class.should == Motel::Location
      rloc1.id.should == loc1.id
    }.should_not raise_error
  end

  it "should permit any user to update_location that does not restrict modify" do
    loc33 = Motel::Location.new :id => 33
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_modify => false

    Motel::Runner.instance.run loc33
    Motel::Runner.instance.run loc1

    loc1a = Motel::Location.new :id => 42, :x => 50, :y => '-10', :movement_strategy => 'invalid',
                                           :remote_queue => 'queue', :parent_id => 33

    lambda{
      rloc1 = Omega::Client::Node.invoke_request('motel::update_location', loc1a)
      rloc1.class.should == Motel::Location
      rloc1.id.should == loc1.id
    }.should_not raise_error

    rloc33= Motel::Runner.instance.locations.find { |l| l.id == 33 }
    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }
    rloc1.x.should == 50
    rloc1.y.should == -10
    rloc1.movement_strategy.should == Motel::MovementStrategies::Stopped.instance
    rloc1.remote_queue.should be_nil
    rloc1.parent.should == rloc33
  end

  it "should permit users with view locations or view location-<id> to track movement of locations" do
    linear = Motel::MovementStrategies::Linear.new(:speed => 5,
                                                   :direction_vector_x => 1,
                                                   :direction_vector_y => 0,
                                                   :direction_vector_z => 0)
    loc1 = Motel::Location.new :id => 42, :x => 0, :y => 0, :z => 0,
                               :movement_strategy => linear,
                               :restrict_view => true
    TestUser.add_privilege('view', 'locations')

    Motel::Runner.instance.run loc1
    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }

    times_moved = 0
    RJR::Dispatcher.add_handler('motel::on_movement') { |nloc|
      nloc.id.should == loc1.id
      times_moved += 1
    }

    # invalid location id
    lambda{
      Omega::Client::Node.invoke_request('motel::track_movement', 'nonexistant', 5)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    rloc1.movement_callbacks.size.should == 0

    # invalid distance
    lambda{
      Omega::Client::Node.invoke_request('motel::track_movement', loc1.id, "5")
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    rloc1.movement_callbacks.size.should == 0

    # invalid distance
    lambda{
      Omega::Client::Node.invoke_request('motel::track_movement', loc1.id, -5)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    rloc1.movement_callbacks.size.should == 0

    # valid call
    lambda{
      rloc = Omega::Client::Node.invoke_request('motel::track_movement', loc1.id, 5)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 1
    rloc1.movement_callbacks.first.min_distance.should == 5

    # ensure subsequent trackings are overwritten
    lambda{
      rloc = Omega::Client::Node.invoke_request('motel::track_movement', loc1.id, 3)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 1
    rloc1.movement_callbacks.first.min_distance.should == 3

    sleep 2
    times_moved.should > 0

    # verify when user no longer has access to location, callbacks are discontinued
    TestUser.clear_privileges
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
    TestUser.add_privilege('view', 'locations')

    proximity_notifications = 0
    RJR::Dispatcher.add_handler('motel::on_proximity') { |nloc1, nloc2|
      nloc1.id.should == loc1.id
      nloc2.id.should == loc2.id
      proximity_notifications += 1
    }

    # invalid location id
    lambda{
      Omega::Client::Node.invoke_request('motel::track_proximity', loc1.id, 'nonexistant', 'proximity', 5)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    loc1.movement_callbacks.size.should == 0

    # invalid location id
    lambda{
      Omega::Client::Node.invoke_request('motel::track_proximity', 'nonexistant', loc2.id, 'proximity', 5)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    Motel::Runner.instance.run loc1
    Motel::Runner.instance.run loc2

    # invalid distance
    lambda{
      Omega::Client::Node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'proximity', "5")
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid distance
    lambda{
      Omega::Client::Node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'proximity', -5)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid event
    lambda{
      Omega::Client::Node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'invalid', 5)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    loc1.movement_callbacks.size.should == 0

    # valid call
    lambda{
      rlocs = Omega::Client::Node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'proximity', 10)
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
      rlocs = Omega::Client::Node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'proximity', 5)
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

    TestUser.clear_privileges
    sleep 2
    loc1.proximity_callbacks.size.should == 0
  end

  it "should permit user to remove registered callbacks" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => Motel::MovementStrategies::Stopped.instance
    loc2 = Motel::Location.new :id => 43, :movement_strategy => Motel::MovementStrategies::Linear.new(:speed => 5)
    TestUser.add_privilege('view', 'locations')

    Motel::Runner.instance.run loc1
    Motel::Runner.instance.run loc2
    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }

    lambda{
      Omega::Client::Node.invoke_request('motel::track_movement',  loc1.id, 3)
      Omega::Client::Node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'proximity', 3)
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 1
    rloc1.proximity_callbacks.size.should == 1

    # invalid location id
    lambda{
      Omega::Client::Node.invoke_request('motel::remove_callbacks', 'nonexistant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    TestUser.clear_privileges

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('motel::remove_callbacks', loc1.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    TestUser.add_privilege('view', 'locations')

    # invalid callback_type
    lambda{
      Omega::Client::Node.invoke_request('motel::remove_callbacks', loc1.id, 'invalid')
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      rloc = Omega::Client::Node.invoke_request('motel::remove_callbacks', loc1.id)
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 0
    rloc1.proximity_callbacks.size.should == 0
  end

  it "should permit user to remove registered callbacks of a certain type" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => Motel::MovementStrategies::Stopped.instance
    loc2 = Motel::Location.new :id => 43, :movement_strategy => Motel::MovementStrategies::Linear.new(:speed => 5)
    TestUser.add_privilege('view', 'locations')

    Motel::Runner.instance.run loc1
    Motel::Runner.instance.run loc2
    rloc1 = Motel::Runner.instance.locations.find { |l| l.id == 42 }

    lambda{
      Omega::Client::Node.invoke_request('motel::track_movement',  loc1.id, 3)
      Omega::Client::Node.invoke_request('motel::track_proximity', loc1.id, loc2.id, 'proximity', 3)
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 1
    rloc1.proximity_callbacks.size.should == 1

    # valid call
    lambda{
      rloc = Omega::Client::Node.invoke_request('motel::remove_callbacks', loc1.id, 'proximity')
      rloc.class.should == Motel::Location
      rloc.id.should == loc1.id
    }.should_not raise_error

    rloc1.movement_callbacks.size.should == 1
    rloc1.proximity_callbacks.size.should == 0
  end

  it "should permit local nodes to save and restore state" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new,
                               :restrict_modify => false
    Motel::Runner.instance.run loc1
    old = Motel::Runner.instance.locations.size
    #fi  = Motel::Runner.instance.locations.first.id

    lambda{
      ret = Omega::Client::Node.invoke_request('motel::save_state', '/tmp/motel-test')
      ret.should be_nil
    }.should_not raise_error

    Motel::Runner.instance.clear
    Motel::Runner.instance.locations.size.should == 0

    lambda{
      ret = Omega::Client::Node.invoke_request('motel::restore_state', '/tmp/motel-test')
      ret.should be_nil
    }.should_not raise_error

    Motel::Runner.instance.locations.size.should == old
    #Motel::Runner.instance.locations.first.id.should == fi
  end
end
