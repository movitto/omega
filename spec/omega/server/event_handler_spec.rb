# Omega Server Event Handler tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/event_handler'

module Omega
module Server
  describe EventHandler do
    describe "#initialize" do
      it "sets defaults" do
        eh = EventHandler.new
        eh.id.should be_nil
        eh.event_id.should be_nil
        eh.event_type.should be_nil
        eh.handlers.should == []
        eh.persist.should be_false
        eh.endpoint_id.should be_nil
      end

      it "sets attributes" do
        h = proc {}
        eh = EventHandler.new :id          => 'eh',
                              :event_id    => :foo,
                              :event_type  => :foo_type,
                              :persist     => true,
                              :endpoint_id => 'eh', &h
        eh.id.should == 'eh'
        eh.event_id.should == :foo
        eh.event_type.should == :foo_type
        eh.handlers.should == [h]
        eh.persist.should be_true
        eh.endpoint_id.should == 'eh'
      end
    end

    describe "#matches?" do
      context "event_id set" do
        context "event_id matches" do
          it "returns true" do
            eh = EventHandler.new :event_id => 'foo'
            eh.matches?(Event.new(:id => 'foo')).should be_true
          end
        end

        context "event_id does not match" do
          it "returns false" do
            eh = EventHandler.new :event_id => 'foobar'
            eh.matches?(Event.new(:id => 'foo')).should be_false
          end
        end
      end

      context "event_type set" do
        context "event_type matches" do
          it "returns true" do
            eh = EventHandler.new :event_type => 'foo'
            eh.matches?(Event.new(:type => 'foo')).should be_true
          end
        end

        context "event_type does not match" do
          it "returns false" do
            eh = EventHandler.new :event_type => 'foobar'
            eh.matches?(Event.new(:type => 'foo')).should be_false
          end
        end
      end
    end

    describe "#exec" do
      it "adds block to handlers" do
        h  = proc {}
        eh = EventHandler.new
        eh.exec &h
        eh.handlers.should == [h]
      end
    end

    describe "#to_json" do
      it "returns handler in json format" do
        handler = EventHandler.new :id => 'eh', :event_id => :foo, :handlers => [:bar],
                                   :persist => true, :endpoint_id => 'eid',
                                   :event_type => :foo_type

        j = handler.to_json
        j.should include('"json_class":"Omega::Server::EventHandler"')
        j.should include('"id":"eh"')
        j.should include('"event_id":"foo"')
        j.should include('"event_type":"foo_type"')
        j.should include('"handlers":["bar"]')
        j.should include('"persist":true')
        j.should include('"endpoint_id":"eid"')
      end
    end

    describe "#json_create" do
      it "return event from json format" do
        j = '{"json_class":"Omega::Server::EventHandler","data":{"id":"eh", "event_id":"foo","handlers":["bar"]}}'

        handler = RJR::JSONParser.parse(j)
        handler.class.should == EventHandler
        handler.id.should == 'eh'
        handler.event_id.should == 'foo'
        handler.handlers.should == ['bar']
      end
    end
  end # describe EventHandler
end # module Server
end # module Omega
