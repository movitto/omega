# Omega Server Event tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/event'
require 'sproc'

require 'timecop'

module Omega
module Server

describe Event do
  describe "#time_elapsed?" do
    context "timestamp has not transpired" do
      it "returns false" do
        e = Event.new :timestamp => Time.now + 10
        e.time_elapsed?.should be_false
      end
    end

    context "timestamp has transpired" do
      it "returns true" do
        e = Event.new :timestamp => Time.now - 10
        e.time_elapsed?.should be_true
      end
    end
  end

  describe "#should_exec?" do
    context "time not elapsed" do
      it "returns false" do
        e = Event.new
        e.should_receive(:time_elapsed?).and_return(false)
        e.should_exec?.should be_false
      end
    end

    context "event already invoked" do
      it "returns false" do
        e = Event.new :invoked => true
        e.should_receive(:time_elapsed?).and_return(true)
        e.should_exec?.should be_false
      end
    end

    context "event is invalid" do
      it "returns false" do
        e = Event.new :invoked => false, :invalid => true
        e.should_receive(:time_elapsed?).and_return(true)
        e.should_exec?.should be_false
      end
    end

    it "returns true" do
      e = Event.new
      e.should_receive(:time_elapsed?).and_return(true)
      e.should_exec?.should be_true
    end
  end

  describe "#initialize" do
    after(:each) do
      Timecop.return
    end

    it "sets defaults" do
      Timecop.freeze
      e = Event.new
      e.timestamp.should == Time.now
      e.handlers.should == []
      e.invoked.should be_false
    end

    it "sets attributes" do
      t = Time.now - 10
      e = Event.new :timestamp => t,
                    :handlers  => [:foobar],
                    :invoked   => true
      e.timestamp.should == t
      e.handlers.should == [:foobar]
      e.invoked.should be_true
    end

    it "converts timestamp" do
      t = Time.now - 10
      e = Event.new :timestamp => t.to_s
      e.timestamp.to_i.should == t.to_i
    end
  end

  describe "#invoke" do
    it "invokes handlers" do
      e = Event.new :handlers => [proc { }]
      e.handlers.first.should_receive :call
      e.invoke
    end

    it "sets invoked to true" do
      e = Event.new
      e.invoke
      e.invoked.should be_true
    end
  end

  describe "#to_json" do
    it "return event in json format" do
      t = Time.now
      event = Event.new :id => 'event321',
                        :timestamp => t,
                        :handlers => [:cb1]
      j = event.to_json
      j.should include('"json_class":"Omega::Server::Event"')
      j.should include('"id":"event321"')
      j.should include('"timestamp":"'+t.to_s+'"')
      j.should include('"handlers":["cb1"]')
    end
  end

  describe "#json_create" do
    it "return event from json format" do
      t = Time.parse('2013-03-10 15:33:41 -0400')
      j = '{"json_class":"Omega::Server::Event","data":{"id":"event321","timestamp":"2013-03-10 15:33:41 -0400","handlers":["cb1"]}}'
      e = JSON.parse(j)

      e.class.should == Omega::Server::Event
      e.id.should == 'event321'
      e.timestamp.to_i.should == t.to_i
      e.handlers.should == ['cb1']
    end
  end
end # describe Event

describe PeriodicEvent do
  before(:each) do
    @registry = Object.new
    @registry.extend(Registry)
  end

  describe "#handle_event" do
    it "copies template event" do
      e = Event.new
      e.should_receive(:to_json).and_call_original
      p = PeriodicEvent.new :template_event => e,
                            :registry => @registry
      p.send(:handle_event)
    end

    it "invokes event" do
      $invoked = false
      # XXX use an sproc here as template event will be copied
      e = Event.new :handlers => [SProc.new { $invoked = true }]
      p = PeriodicEvent.new :template_event => e,
                            :registry => @registry
      p.invoke
      $invoked.should be_true
    end

    it "schedules new periodic event" do
      e = Event.new :id => 'test'
      p = PeriodicEvent.new :template_event => e,
                            :registry => @registry
      lambda {
        p.invoke
      }.should change{@registry.entities.size}.by(1)
      r = @registry.instance_variable_get(:@entities).last
      r.should be_an_instance_of(PeriodicEvent)
      r.template_event.id.should == e.id
      r.registry.should == @registry
      r.interval.should == p.interval
    end
  end

  describe "#initialize" do
    it "sets defaults" do
      event = PeriodicEvent.new
      event.interval.should == PeriodicEvent::DEFAULT_INTERVAL
      event.template_event.should be_nil
    end

    it "sets attributes" do
      event = PeriodicEvent.new :interval => 500, :template_event => :foo
      event.interval.should == 500
      event.template_event.should == :foo
    end

    it "adds handler to handle_event" do
      event = PeriodicEvent.new
      event.handlers.size.should == 1
      event.should_receive(:handle_event)
      event.invoke
    end
  end

  describe "#to_json" do
    it "returns event in json format" do
      event = PeriodicEvent.new :interval => 500, :template_event => :foo

      j = event.to_json
      j.should include('"json_class":"Omega::Server::PeriodicEvent"')
      j.should include('"interval":500')
      j.should include('"template_event":"foo"')
    end
  end

  describe "#json_create" do
    it "return event from json format" do
      j = '{"json_class":"Omega::Server::PeriodicEvent","data":{"id":"","timestamp":null,"callbacks":[""],"interval":500,"template_event":"foo"}}'

      event = JSON.parse(j)
      event.class.should == PeriodicEvent
      event.interval.should == 500
      event.template_event.should == "foo"
    end
  end
end # describe PeriodicEvent

describe EventHandler do
  describe "#initialize" do
    it "sets defaults" do
      eh = EventHandler.new
      eh.event_id.should be_nil
      eh.handlers.should == []
    end

    it "sets attributes" do
      h = proc {}
      eh = EventHandler.new :event_id => :foo, &h
      eh.event_id.should == :foo
      eh.handlers.should == [h]
    end
  end

  describe "#to_json" do
    it "returns handler in json format" do
      handler = EventHandler.new :event_id => :foo, :handlers => [:bar]

      j = handler.to_json
      j.should include('"json_class":"Omega::Server::EventHandler"')
      j.should include('"event_id":"foo"')
      j.should include('"handlers":["bar"]')
    end
  end

  describe "#json_create" do
    it "return event from json format" do
      j = '{"json_class":"Omega::Server::EventHandler","data":{"event_id":"foo","handlers":["bar"]}}'

      handler = JSON.parse(j)
      handler.class.should == EventHandler
      handler.event_id.should == 'foo'
      handler.handlers.should == ['bar']
    end
  end

end # describe EventHandler

end # module Server
end # module Omega
