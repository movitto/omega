# Location EventDispatcher Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  let(:loc)   { build(:location) }
  let(:other) { build(:location) }

  describe "#callbacks_from_args" do
    it "initializes callbacks" do
      cbs = {}
      loc.callbacks_from_args :callbacks => cbs
      loc.callbacks.should == cbs
    end

    it "converts valid string callback keys to symbols" do
      mcbs = []
      loc.callbacks_from_args :callbacks => {'movement' => mcbs}
      loc.callbacks.should == {:movement => mcbs}
    end

    context "invalid callback specified" do
      it "raises argument error" do
        lambda {
          loc.callbacks_from_args :callbacks => {'foobar' => []}
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#raise_event" do
    it "invokes registered event callbacks" do
      ran1 = ran2 = ran3 = false
      loc.callbacks['moved']  << Omega::Server::Callback.new { ran1 = true }
      loc.callbacks['moved']  << Omega::Server::Callback.new { ran2 = true }
      loc.callbacks['stopped'] << Omega::Server::Callback.new { ran3 = true }
      loc.raise_event 'moved'
      ran1.should be_true
      ran2.should be_true
      ran3.should be_false
    end

    it "passes arguments to callbacks" do
      la,a = nil,nil
      loc.callbacks['moved'] << Omega::Server::Callback.new { |*args| la,a = *args }
      loc.raise_event 'moved', 42
      la.should == loc
      a.should == 42
    end

    context "callback#should_invoke? returns false" do
      it "skips callback" do
        ran1 = ran2 = false
        loc.callbacks['moved']  << Omega::Server::Callback.new(:only_if => proc { false }) { ran1 = true }
        loc.callbacks['moved']  << Omega::Server::Callback.new { ran2 = true }
        loc.raise_event 'moved'
        ran1.should be_false
        ran2.should be_true
      end
    end
  end

  describe "#callbacks_json" do
    it "returns callbacks json data hash" do
      loc.callbacks_json.should be_an_instance_of(Hash)
    end

    it "returns callbacks in json data hash" do
      cbs = {:movement => []}
      loc.callbacks = cbs
      loc.callbacks_json[:callbacks].should == cbs
    end
  end

  describe "#callbacks_eql?" do
    before(:each) do
      loc.callbacks = other.callbacks = {}
    end

    context "callbacks do not equal other callbacks" do
      it "returns false" do
        loc.callbacks = {:rotation => [proc{}]}
        loc.callbacks_eql?(other).should be_false
      end
    end

    it "returns true" do
      loc.callbacks_eql?(other).should be_true
    end
  end
end # describe Location
end # module Motel
