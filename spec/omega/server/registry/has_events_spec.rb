# Omega Server Registry HasEvents Mixin tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

# test through registry inclusion
require 'omega/server/registry'

module Omega
module Server
module Registry
  describe HasEvents do
    before(:each) do
      @registry = Object.new
      @registry.extend(Registry)
    end

    describe "#on" do
      it "registers a handler to an event" do
        ran = nil
        @registry.on(:foobar) { |p| ran = p }
        @registry.raise_event :foobar, :barfoo
        ran.should == :barfoo
      end

      it "registers a handler to multiple events" do
        ran = nil
        @registry.on([:foobar, :test]) { |p| ran = p }
        @registry.raise_event :foobar, :barfoo
        ran.should == :barfoo

        ran = nil
        @registry.raise_event :test, :hi
        ran.should == :hi
      end
    end

    describe "#raise_event" do
      it "invokes the handlers for the specified event" do
        ran = nil
        @registry.on(:foobar) { ran = true }
        @registry.raise_event :foobar
        ran.should be_true
      end

      it "passes the argument list to event handlers" do
        params = nil
        @registry.on(:foobar) { |p1,p2| params = [p1,p2] }
        @registry.raise_event :foobar, :barfoo, :raboof
        params.should == [:barfoo, :raboof]
      end
    end
  end # describe HasEvents
end # module Registry
end # module Server
end # module Omega
