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
