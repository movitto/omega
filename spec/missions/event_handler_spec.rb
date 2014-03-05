# Missions Event Handler class tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/event_handler'

module Missions
module EventHandlers
describe DSL do
  describe "#initialize" do
    it "should initialize missions callbacks from args" do
      eh = Missions::EventHandlers::DSL.new :event_id => 'event',
                                            :missions_callbacks => ['cb']
      eh.missions_callbacks.should == ['cb']
      eh.event_id.should == 'event'
    end
  end

  describe "#exec" do
    it "adds cb to mission callbacks" do
      h = proc {}
      eh = Missions::EventHandlers::DSL.new
      eh.exec h
      eh.missions_callbacks.should == [h]
    end
  end

  describe "#to_json" do
    it "should return event handler in json format" do
      eh = Missions::EventHandlers::DSL.new :event_id => 'event',
                                            :missions_callbacks => ['cb']
      j = eh.to_json
      j.should include('"json_class":"Missions::EventHandlers::DSL"')
      j.should include('"event_id":"event"')
      j.should include('"missions_callbacks":["cb"]')
    end
  end

  describe "#invoke" do
    it "should invoke missions callbacks with args" do
      cb1 = proc {}
      cb2 = proc {}
      eh = Missions::EventHandlers::DSL.new :missions_callbacks => [cb1, cb2]
      cb1.should_receive(:call).with(42)
      cb2.should_receive(:call).with(42)
      eh.invoke 42
    end
  end
end # describe DSL
end # module EventHandlers
end # module Missions
