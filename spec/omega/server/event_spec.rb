# Omega Server Event tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/event'

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
        e.id.should be_nil
        e.registry.should be_nil
        e.type.should be_nil
      end

      it "sets attributes" do
        t = Time.now - 10
        registry = Object.new
        e = Event.new :timestamp => t,
                      :handlers  => [:foobar],
                      :registry  => registry,
                      :id => 'e1',
                      :type => 'te1'
        e.timestamp.should == t
        e.handlers.should == [:foobar]
        e.id.should == 'e1'
        e.registry.should == registry
        e.type.should == 'te1'
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
    end

    describe "#to_json" do
      it "return event in json format" do
        t = Time.now
        event = Event.new :id => 'event321',
                          :type => 'event_type',
                          :timestamp => t,
                          :handlers => [:cb1]
        j = event.to_json
        j.should include('"json_class":"Omega::Server::Event"')
        j.should include('"id":"event321"')
        j.should include('"type":"event_type"')
        j.should include('"timestamp":"'+t.to_s+'"')
        j.should include('"handlers":["cb1"]')
      end
    end

    describe "#json_create" do
      it "return event from json format" do
        t = Time.parse('2013-03-10 15:33:41 -0400')
        j = '{"json_class":"Omega::Server::Event","data":{"id":"event321","timestamp":"2013-03-10 15:33:41 -0400","handlers":["cb1"]}}'
        e = RJR::JSONParser.parse(j)

        e.class.should == Omega::Server::Event
        e.id.should == 'event321'
        e.timestamp.to_i.should == t.to_i
        e.handlers.should == ['cb1']
      end
    end
  end # describe Event
end # module Server
end # module Omega
