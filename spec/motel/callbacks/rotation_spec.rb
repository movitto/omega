# Rotation Callback tests
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'
require 'motel/callbacks/rotation'

module Motel::Callbacks
describe Rotation do
  describe "should_invoke?" do
    it "should return true" do
      r = Rotation.new
      l = build(:location, :orx => 1, :ory => 0, :orz => 0)
      r.should_invoke?(l, -1, 0, 0).should be_true
    end

    context "axis-angle set" do
      before(:each) do
        @r = Rotation.new :rot_theta => 3.13,
                          :axis_x    => 0,
                          :axis_y    => 0,
                          :axis_z    => 1
      end

      context "location rotated by at least specified angle along axis" do
        it "returns true" do
          l = Motel::Location.new :orientation => [0,1,0]
          @r.should_invoke?(l, 0, -1, 0).should be_true
        end
      end

      context "location did not rotate minimum axis-angle" do
        it "returns false" do
          l = Motel::Location.new :orientation => [0,0,1]
          @r.should_invoke?(l, 0, 0, 1).should be_false
          @r.should_invoke?(l, 0.57, 0.57, 0.57).should be_false
        end
      end
    end

    context "axis not set" do
      before(:each) do
        @r = Rotation.new :rot_theta => 3.13
      end

      context "location movement strategy is includes Rotatable mixin" do
        before(:each) do
          @l = Motel::Location.new :orientation => [0,1,0],
                 :movement_strategy =>
                   Motel::MovementStrategies::Rotate.new(:rot_x => 0,
                                                         :rot_y => 0,
                                                         :rot_z => 1)
        end

        context "location rotated by at least specified angle along its rotation axis" do
          it "returns true" do
            @r.should_invoke?(@l, 0, -1, 0).should be_true
          end
        end

        context "location did not rotate by minimum angle along its rotation axis" do
          it "returns false" do
            @l.orientation = [0,0,1]
            @r.should_invoke?(@l, 0, 0, 1).should be_false
          end
        end
      end

      it "returns false" do
        l = Motel::Location.new :orientation => [0,1,0]
        @r.should_invoke?(l, 0, -1, 0).should be_false
      end
    end
  end

  describe "#invoke" do
    before(:each) do
      @cb = proc {}
      @r = Rotation.new :handler => @cb
      @l = Motel::Location.new
    end

    it "invokes handler with location,angle rotated" do
      @r.should_receive(:get_rotation).and_return(42)
      @cb.should_receive(:call).with(@l, 42)
      @r.invoke @l, 0, 0, 1
    end

    it "resets tracked orientation" do
      @r.should_receive(:get_rotation).and_return(42)
      @r.invoke @l, 0, 0, 1
      @m.instance_variable_get(:@orig_ox).should be_nil
      @m.instance_variable_get(:@orig_oy).should be_nil
      @m.instance_variable_get(:@orig_oz).should be_nil
    end
  end

  describe "#to_json" do
    it "returns callback in json format" do
      cb = Rotation.new :endpoint_id => 'baz',
                        :rot_theta => 3.14,
                        :axis_x    => 1,
                        :axis_y    => 0,
                        :axis_z    => 0

      j = cb.to_json
      j.should include('"json_class":"Motel::Callbacks::Rotation"')
      j.should include('"endpoint_id":"baz"')
      j.should include('"rot_theta":3.14')
      j.should include('"axis_x":1')
      j.should include('"axis_y":0')
      j.should include('"axis_z":0')
    end
  end

  describe "#json_create" do
    it "returns callback from json format" do
      j = '{"json_class":"Motel::Callbacks::Rotation","data":{"endpoint_id":"baz","rot_theta":3.14,"axis_x":1,"axis_y":0,"axis_z":0}}'
      cb = RJR.parse_json(j)

      cb.class.should == Motel::Callbacks::Rotation
      cb.endpoint_id.should == "baz"
      cb.rot_theta.should == 3.14
      cb.axis_x.should == 1
      cb.axis_y.should == 0
      cb.axis_z.should == 0
    end
  end

end # describe Rotation
end # module Motel::Callbacks
