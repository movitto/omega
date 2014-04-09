# Omega Server Periodic Event tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/events/periodic'

module Omega
module Server
  describe PeriodicEvent do
    before(:each) do
      @registry = Object.new
      @registry.extend(Registry)
      @e = Event.new
      @p = PeriodicEvent.new :id => 'periodic',
                             :template_event => @e,
                             :registry => @registry
    end

    describe "#handle_event" do
      it "copies template event" do
        @e.should_receive(:to_json).and_call_original
        @p.send(:handle_event)
      end

      it "generates id for next periodic event" do
        @p.invoke
        e = @registry.instance_variable_get(:@entities).last
        e.id.should == 'periodic-1'

        e.registry = @registry
        e.invoke
        e1 = @registry.instance_variable_get(:@entities).last
        e1.id.should == 'periodic-2'
      end

      it "adds event to registry to be run" do
        e = Event.new :id => 'test'
        @p.template_event = e
        lambda {
          @p.invoke
        }.should change{@registry.entities.size}.by(2)
        r = @registry.instance_variable_get(:@entities).first
        r.should be_an_instance_of(Event)
        r.id.should == e.id
      end

      it "schedules new periodic event" do
        e = Event.new :id => 'test'
        @p.template_event = e
        lambda {
          @p.invoke
        }.should change{@registry.entities.size}.by(2)
        r = @registry.instance_variable_get(:@entities).last
        r.should be_an_instance_of(PeriodicEvent)
        r.template_event.id.should == e.id
        r.interval.should == @p.interval
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

        event = RJR::JSONParser.parse(j)
        event.class.should == PeriodicEvent
        event.interval.should == 500
        event.template_event.should == "foo"
      end
    end
  end # describe PeriodicEvent
end # module Server
end # module Omega
