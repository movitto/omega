# ChangedStrategy Callback tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'
require 'motel/callbacks/changed_strategy'

module Motel::Callbacks
describe ChangedStrategy do
  describe "should_invoke?" do
    it "should return true" do
      cs = ChangedStrategy.new
      cs.should_invoke?(build(:location)).should be_true
    end

    context "orig ms set" do
      context "location ms is different than orig ms" do
        it "should return true" do
          cs = ChangedStrategy.new :orig_ms =>
                 Motel::MovementStrategies::Linear.new
          cs.should_invoke?(build(:location, :ms =>
            Motel::MovementStrategies::Stopped.instance)).should be_true
        end
      end

      context "location ms is same as orig ms" do
        it "should return false" do
          cs = ChangedStrategy.new :orig_ms =>
                 Motel::MovementStrategies::Linear.new
          cs.should_invoke?(build(:location, :ms =>
            Motel::MovementStrategies::Linear.new)).should be_false
        end
      end
    end
  end

  describe "#invoke" do
    before(:each) do
      @cb = proc {}
      @ms = Motel::MovementStrategies::Linear.new
      @cs = ChangedStrategy.new :handler => @cb, :orig_ms => @ms
      @l  = Motel::Location.new :ms => Motel::MovementStrategies::Linear.new
    end

    it "invokes handler with loc,orig ms" do
      @cb.should_receive(:call).with(@l, @ms)
      @cs.invoke @l
    end

    it "resets orig ms" do
      @cs.invoke @l
      @cs.orig_ms.should == @l.ms
    end
  end

  describe "#to_json" do
    it "returns callback in json format" do
      l  = Motel::MovementStrategies::Linear.new
      cb = ChangedStrategy.new :endpoint_id => 'baz', :orig_ms => l

      j = cb.to_json
      j.should include('"json_class":"Motel::Callbacks::ChangedStrategy"')
      j.should include('"endpoint_id":"baz"')
      j.should include('"orig_ms":' + l.to_json)
    end
  end

  describe "#json_create" do
    it "returns callback from json format" do
      j = '{"json_class":"Motel::Callbacks::ChangedStrategy","data":{"endpoint_id":"baz","orig_ms":{"json_class":"Motel::MovementStrategies::Linear","data":{"step_delay":1,"speed":null,"dx":1.0,"dy":0.0,"dz":0.0,"rot_theta":0,"rot_x":0,"rot_y":0,"rot_z":1}}}}'
      cb = RJR::JSONParser.parse(j)

      cb.class.should == Motel::Callbacks::ChangedStrategy
      cb.endpoint_id.should == "baz"
      cb.orig_ms.should be_an_instance_of Motel::MovementStrategies::Linear
    end
  end

end # describe Movement
end # module Motel::Callbacks
