# Periodic Event class tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Missions::Events::Periodic do
  it "should set periodic event defaults" do
    event = Missions::Events::Periodic.new
    event.interval.should == Missions::Events::Periodic::DEFAULT_INTERVAL
    event.template_event.should be_nil
  end

  it "should accept periodic event args" do
    event = Missions::Events::Periodic.new :interval => 500, :event => :foo
    event.interval.should == 500
    event.template_event.should == :foo
  end

  it "should run callback to invoke copy of template event" do
    event = Missions::Events::Periodic.new
    event.callbacks.size.should == 1
    # TODO
  end

  it "should be convertable to json" do
    event = Missions::Events::Periodic.new :interval => 500, :event => :foo

    j = event.to_json
    j.should include('"json_class":"Missions::Events::Periodic"')
    j.should include('"interval":500')
    j.should include('"event":"foo"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Missions::Events::Periodic","data":{"id":"","timestamp":null,"callbacks":["#<Proc:0x00000002e5e5c8@/home/mmorsi/workspace/omega/lib/missions/events/periodic.rb:27>"],"interval":500,"event":"foo"}}'

    event = JSON.parse(j)
    event.class.should == Missions::Events::Periodic
    event.interval.should == 500
    event.template_event.should == "foo"
  end
end
