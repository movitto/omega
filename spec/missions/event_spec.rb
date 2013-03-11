# Event class tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Missions::Event do
  it "should set event defaults" do
    event = Missions::Event.new
    event.id.should == ""
    #event.timestamp.should be_nil # TODO
    event.callbacks.should == []
  end

  it "should successfully accept and set event params" do
    t = Time.now
    event = Missions::Event.new :id => 'event321',
                                :timestamp => t,
                                :callbacks => [:cb1]
    event.id.should == 'event321'
    event.timestamp.should == t
    event.callbacks.should == [:cb1]
  end

  it "should convert string timestampe into timestamp" do
    t = Time.new('2013-01-01 00:00:00 -0500')
    e = Missions::Event.new :timestamp => t.to_s
    e.timestamp.should == t
  end

  it "should verify validity of event" do
    # TODO
  end

  it "should return boolean indicating if time to run event has elapsed" do
    e = Missions::Event.new :timestamp => Time.now - 10
    e.time_elapsed?.should be_true

    e = Missions::Event.new :timestamp => Time.now + 10
    e.time_elapsed?.should be_false
  end

  it "should be convertable to json" do
    t = Time.now
    event = Missions::Event.new :id => 'event321',
                                :timestamp => t,
                                :callbacks => [:cb1]
    j = event.to_json
    j.should include('"json_class":"Missions::Event"')
    j.should include('"id":"event321"')
    j.should include('"timestamp":"'+t.to_s+'"')
    j.should include('"callbacks":["cb1"]')
  end

  it "should be convertable from json" do
    t = Time.new('2013-03-10 15:33:41 -0400')
    j = '{"json_class":"Missions::Event","data":{"id":"event321","timestamp":"2013-03-10 15:50:16 -0400","callbacks":["cb1"]}}'
    e = JSON.parse(j)

    e.class.should == Missions::Event
    e.id.should == 'event321'
    e.timestamp.should == t
    e.callbacks.should == ['cb1']
  end
end
