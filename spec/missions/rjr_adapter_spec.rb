# rjr adapter tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/local_node'

describe Missions::RJRAdapter do

  before(:each) do
    @event1   = Missions::Event.new   :id => 'nevent1', :timestamp => Time.now
    @event2   = Missions::Event.new   :id => 'nevent2', :timestamp => (Time.now + 100)
    @mission1 = Missions::Mission.new :id => 'nmission1'
  end

  after(:each) do
    Missions::Registry.instance.terminate
    FileUtils.rm_f '/tmp/missions-test' if File.exists?('/tmp/missions-test')
  end

  it "should permit users with create mission_events to create_event" do
    Missions::Registry.instance.init

    # invalid type
    lambda {
      Omega::Client::Node.invoke_request('missions::create_event', 1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid data, no permissions
    lambda{
      Omega::Client::Node.invoke_request('missions::create_event', @event1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('create', 'mission_events')

    # valid call
    sevent = nil
    lambda{
      sevent = Omega::Client::Node.invoke_request('missions::create_event', @event1)
    }.should_not raise_error
    sevent.class.should == Missions::Event
    sevent.id.should == @event1.id

    Missions::Registry.instance.events.size.should    == 1
    Missions::Registry.instance.events.collect { |e| e.id }.should include(@event1.id)
  end

  it "should permit users with create missions to create_mission" do
    Missions::Registry.instance.init

    # invalid type
    lambda {
      Omega::Client::Node.invoke_request('missions::create_mission', 1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid data, no permissions
    lambda{
      Omega::Client::Node.invoke_request('missions::create_mission', @mission1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('create', 'missions')

    # valid call
    smission = nil
    lambda{
      smission = Omega::Client::Node.invoke_request('missions::create_mission', @mission1)
    }.should_not raise_error
    smission.class.should == Missions::Mission
    smission.id.should == @mission1.id

    Missions::Registry.instance.missions.size.should    == 1
    Missions::Registry.instance.missions.collect { |e| e.id }.should include(@mission1.id)
  end

  it "should permit users with view missions or view mission-<id> to get_missions" do
    Missions::Registry.instance.init

    mission123 = Missions::Mission.new :id   => "mission123"
    mission234 = Missions::Mission.new :id   => "mission234"
    Missions::Registry.instance.create mission123
    Missions::Registry.instance.create mission234

    missions = Omega::Client::Node.invoke_request('missions::get_missions')
    missions.size.should == 0

    TestUser.add_privilege('view', 'missions')
    missions = Omega::Client::Node.invoke_request('missions::get_missions')
    missions.size.should == 2
    missions.collect { |m| m.id }.should include(mission123.id)
    missions.collect { |m| m.id }.should include(mission234.id)

    TestUser.clear_privileges

    TestUser.add_privilege('view', 'mission-mission123')
    missions = Omega::Client::Node.invoke_request('missions::get_missions')
    missions.size.should == 1
    missions.collect { |m| m.id }.should include(mission123.id)
  end

  it "should permit users with view unassigned missions to get_missions that are unassigned" do
    Missions::Registry.instance.init

    mission123 = Missions::Mission.new :id   => "mission123"
    mission234 = Missions::Mission.new :id   => "mission234", :assigned_to_id => 'user123'
    Missions::Registry.instance.create mission123
    Missions::Registry.instance.create mission234

    TestUser.add_privilege('view', 'unassigned_missions')
    missions = Omega::Client::Node.invoke_request('missions::get_missions')
    missions.size.should == 1
    missions.collect { |m| m.id }.should include(mission123.id)
  end

  it "should get_mission by id" do
    Missions::Registry.instance.init

    mission123 = Missions::Mission.new :id   => "mission123"
    mission234 = Missions::Mission.new :id   => "mission234"
    Missions::Registry.instance.create mission123
    Missions::Registry.instance.create mission234

    TestUser.add_privilege('view', 'missions')
    mission = Omega::Client::Node.invoke_request('missions::get_mission', 'with_id', 'mission123')
    mission.class.should == Missions::Mission
    mission.id.should == mission123.id
  end

  it "should get missions assignable to the specified user" do
    Missions::Registry.instance.init

    user1 = Users::User.new :id => 'user1'
    Users::Registry.instance.create user1

    mission123 = Missions::Mission.new :id   => "mission123", :requirements => proc { |m,u,n| false }
    mission234 = Missions::Mission.new :id   => "mission234"
    Missions::Registry.instance.create mission123
    Missions::Registry.instance.create mission234

    TestUser.add_privilege('view', 'missions')
    missions = Omega::Client::Node.invoke_request('missions::get_mission', 'assignable_to', user1)
    missions.size.should == 1
    missions.collect { |m| m.id }.should include(mission234.id)

    missions = Omega::Client::Node.invoke_request('missions::get_mission', 'assignable_to', user1.id)
    missions.size.should == 1
    missions.collect { |m| m.id }.should include(mission234.id)
  end

  it "should get mission assigned to the specified user" do
    Missions::Registry.instance.init

    user1 = Users::User.new :id => 'user1'
    Users::Registry.instance.create user1

    mission123 = Missions::Mission.new :id   => "mission123", :assigned_to_id => user1.id
    mission234 = Missions::Mission.new :id   => "mission234"
    Missions::Registry.instance.create mission123
    Missions::Registry.instance.create mission234

    TestUser.add_privilege('view', 'missions')
    mission = Omega::Client::Node.invoke_request('missions::get_mission', 'assigned_to', user1)
    mission.class.should == Missions::Mission
    mission.id.should == mission123.id

    mission = Omega::Client::Node.invoke_request('missions::get_mission', 'assigned_to', user1.id)
    mission.class.should == Missions::Mission
    mission.id.should == mission123.id
  end

  it "should get active missions" do
    Missions::Registry.instance.init

    mission123 = Missions::Mission.new :id   => "mission123", :assigned_time => Time.now, :timeout => 10
    mission234 = Missions::Mission.new :id   => "mission234"
    Missions::Registry.instance.create mission123
    Missions::Registry.instance.create mission234

    TestUser.add_privilege('view', 'missions')
    missions = Omega::Client::Node.invoke_request('missions::get_mission', 'is_active', true)
    missions.size.should == 1
    missions.collect { |m| m.id }.should include(mission123.id)

    missions = Omega::Client::Node.invoke_request('missions::get_mission', 'is_active', false)
    missions.size.should == 1
    missions.collect { |m| m.id }.should include(mission234.id)
  end

  it "should permit users with modify users or modify user-<id> to assign mission to user" do
    Missions::Registry.instance.init

    testuser1 = Users::User.new :id => 'user42'
    Users::Registry.instance.create testuser1

    mission123 = Missions::Mission.new :id   => "mission123"
    mission234 = Missions::Mission.new :id   => "mission234"
    mission345 = Missions::Mission.new :id   => "mission345", :requirements => proc { |m,u,n| false }
    Missions::Registry.instance.create mission123
    Missions::Registry.instance.create mission234
    Missions::Registry.instance.create mission345

    # invalid mission id
    lambda{
      Omega::Client::Node.invoke_request('missions::assign_mission', 'invalid', testuser1.id)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid user id
    lambda{
      Omega::Client::Node.invoke_request('missions::assign_mission', mission123.id, 'invalid')
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('missions::assign_mission', mission123.id, testuser1.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'users')

    # not assignable to user
    lambda{
      Omega::Client::Node.invoke_request('missions::assign_mission', mission345.id, testuser1.id)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)

    # valid call
    mission = nil
    lambda{
      mission = Omega::Client::Node.invoke_request('missions::assign_mission', mission123.id, testuser1.id)
    }.should_not raise_error
    mission.id.should == mission123.id

    # should not permit more that one mission to be assigned to a user at a time
    lambda{
      Omega::Client::Node.invoke_request('missions::assign_mission', mission234.id, testuser1.id)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)
  end

  it "should handle manufactured events and run them as mission events" do
    attacker = Manufactured::Ship.new      :id => 'attacker'
    defender = Manufactured::Ship.new      :id => 'defender'

    Missions::Registry.instance.events.size.should == 0
    Omega::Client::Node.invoke_request('manufactured::event_occurred', 'attacked', attacker, defender)
    Missions::Registry.instance.events.size.should == 1
    Missions::Registry.instance.events.first.class.should == Missions::Events::Manufactured
    Missions::Registry.instance.events.first.manufactured_event_args.size.should == 3
    Missions::Registry.instance.events.first.manufactured_event_args.first.should == 'attacked'
    Missions::Registry.instance.events.first.id.should == attacker.id + '_attacked'
  end

  it "should permit local nodes to save and restore state" do
    Missions::Registry.instance.create @mission1
    Missions::Registry.instance.create @event2
    oldmn = Missions::Registry.instance.missions.size
    olden = Missions::Registry.instance.events.size

    ret = nil
    lambda{
      ret = Omega::Client::Node.invoke_request('missions::save_state', '/tmp/missions-test')
    }.should_not raise_error
    ret.should be_nil

    Missions::Registry.instance.init
    Missions::Registry.instance.missions.size.should == 0
    Missions::Registry.instance.events.size.should == 0

    lambda{
      ret = Omega::Client::Node.invoke_request('missions::restore_state', '/tmp/missions-test')
    }.should_not raise_error
    ret.should be_nil

    Missions::Registry.instance.missions.size.should == oldmn
    Missions::Registry.instance.events.size.should   == olden
    Missions::Registry.instance.missions.find { |mission| mission.id == @mission1.id }.should_not be_nil
    Missions::Registry.instance.events.find   { |event|   event.id   == @event2.id   }.should_not be_nil
  end
end
