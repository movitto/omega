# Manufactured Event Handler class tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/event_handler'

module Manufactured
describe EventHandler do
  describe "#initialize" do
    it "should initialize event args from args" do
      eh = EventHandler.new :event_args => ['foo']
      eh.event_args.should == ['foo']
    end
  end

  describe "#matches" do
    context "base event handler does not match" do
      it "returns false" do
        eh = EventHandler.new :event_type => 'et1'
        eh.matches?(Omega::Server::Event.new(:type => 'et2')).should be_false
      end
    end

    context "event does not trigger handler" do
      it "returns false" do
        evnt = Omega::Server::Event.new(:type => 'et1')
        evnt.should_receive(:trigger_handler?).and_return(false)
        eh = EventHandler.new :event_type => 'et1'
        eh.matches?(evnt).should be_false
      end
    end

    context "event handler matches and is triggered by event" do
      it "returns true" do
        evnt = Omega::Server::Event.new(:type => 'et1')
        evnt.should_receive(:trigger_handler?).and_return(true)
        eh = EventHandler.new :event_type => 'et1'
        eh.matches?(evnt).should be_true
      end
    end
  end

  describe "#to_json" do
    it "should return event handler in json format" do
      eh = EventHandler.new :event_type => 'eh1', :event_args => ['foo']
      j = eh.to_json
      j.should include('"json_class":"Manufactured::EventHandler"')
      j.should include('"event_type":"eh1"')
      j.should include('"event_args":["foo"]')
    end
  end
end # describe EventHandler
end # module Manufactured
