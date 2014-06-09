# Omega Server Callback tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/callback'

module Omega::Server
describe Callback do
  describe "#initialize" do
    it "sets attributes" do
      p = proc {}
      h = proc {}
      c = Callback.new :only_if     => p,
                       :endpoint_id => 'node1',
                       :event_type  => :evnt,
                       &h
      c.only_if.should == p
      c.endpoint_id.should == 'node1'
      c.event_type.should == :evnt
      c.handler.should == h
    end
  end

  describe "#should_invoke" do
    it "defaults to true" do
      c = Callback.new
      c.should_invoke?.should be_true
    end

    it "returns value of only_if invocation" do
      c = Callback.new :only_if => proc { |i| i % 2 == 0 }
      c.should_invoke?(1).should be_false
      c.should_invoke?(2).should be_true
    end
  end

  describe "#invoke" do
    it "should call handler w/ the specified args" do
      arg = nil
      c = Callback.new { |a| arg = a }
      c.invoke 42
      arg.should == 42
    end
  end
end # describe Callback
end # module Omega::Server
