# Location EventDispatcher Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  describe "#raise_event" do
    it "invokes registered event callbacks" do
      ran1 = ran2 = ran3 = false
      l = build(:location)
      l.callbacks['moved']  << Omega::Server::Callback.new { ran1 = true }
      l.callbacks['moved']  << Omega::Server::Callback.new { ran2 = true }
      l.callbacks['stopped'] << Omega::Server::Callback.new { ran3 = true }
      l.raise_event 'moved'
      ran1.should be_true
      ran2.should be_true
      ran3.should be_false
    end

    it "passes arguments to callbacks" do
      la,a = nil,nil
      l = build(:location)
      l.callbacks['moved'] << Omega::Server::Callback.new { |*args| la,a = *args }
      l.raise_event 'moved', 42
      la.should == l
      a.should == 42
    end

    context "callback#should_invoke? returns false" do
      it "skips callback" do
        ran1 = ran2 = false
        l = build(:location)
        l.callbacks['moved']  << Omega::Server::Callback.new(:only_if => proc { false }) { ran1 = true }
        l.callbacks['moved']  << Omega::Server::Callback.new { ran2 = true }
        l.raise_event 'moved'
        ran1.should be_false
        ran2.should be_true
      end
    end
  end
end # describe Location
end # module Motel
