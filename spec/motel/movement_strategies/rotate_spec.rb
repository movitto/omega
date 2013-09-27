# rotate movement strategy tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/location'
require 'motel/movement_strategies/rotate'

module Motel::MovementStrategies
describe Rotatable do

  describe "#valid_rotation?" do
    before(:each) do
      @r = Rotate.new
    end

    context "rot_theta is invalid" do
      it "returns false" do
        @r.rot_theta = :foo
        @r.should_not be_valid
        @r.rot_theta = -10.11
        @r.valid?.should be_false

        @r.rot_theta = 9.89
        @r.valid?.should be_false
      end
    end

    context "rot axis is invalid" do
      it "returns false" do
        @r.rot_x = :foo
        @r.valid?.should be_false

        @r.rot_x = -10.11
        @r.valid?.should be_false

        @r.rot_x = 10.22
        @r.valid?.should be_false

        @r.rot_x = -0.75
        @r.valid?.should be_false
      end
    end

    it "returns true" do
      @r.should be_valid
    end
  end

  describe "#rotate" do
    it "rotates location by rot_theta scaled with elapsed time around rot axis" do
      rot = Rotate.new :speed => 5, :step_delay => 5
      rt,rx,ry,rz  = rot.rot_theta, rot.rot_x, rot.rot_y, rot.rot_z

      p = Motel::Location.new
      orientation  = [1,0,0]
      l = Motel::Location.new(:parent => p,
                              :movement_strategy => rot,
                              :orientation  => orientation)

      # move and validate
      rot.move l, 1
      l.orientation.should ==
        Motel.rotate(*orientation, rt, rx, ry, rz)

      orientation  = l.orientation

      rot.move l, 5
      l.orientation.should ==
        Motel.rotate(*orientation, 5*rt, rx, ry, rz)
    end
  end

end # describe Rotatable

describe Rotate do
  describe "#initialize" do
    it "sets defaults" do
      r = Rotate.new
      r.rot_theta.should == 0
      r.rot_x.should == 0
      r.rot_y.should == 0
      r.rot_z.should == 1
    end

    it "sets arguments" do
      rot = Rotate.new :speed => 5, :rot_theta => 0.25,
                       :rot_x => -1, :rot_y => 0, :rot_z => 0
      rot.rot_theta.should == 0.25
      rot.rot_x.should == -1
      rot.rot_y.should == 0
      rot.rot_z.should == 0
    end
  end

  describe "#valid?" do
    it "dispatches to valid_rotation?" do
      r = Rotate.new
      r.should_receive(:valid_rotation?)
      r.valid?
    end
  end

  describe "#rotate" do
    context "rotate is not valid" do
      it "does not rotate location" do
        rot = Rotate.new :rot_theta => -10
        l = build(:location)

        lambda {
          rot.move l, 5
        }.should_not change(l, :orientation)
      end
    end
  end

  describe "#to_json" do
    it "returns rotate in json format" do
      rot = Rotate.new :rot_theta => 0.1, :step_delay => 1,
                       :rot_x => 0, :rot_y => 0, :rot_z => -1

      j = rot.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Rotate"')
      j.should include('"step_delay":1')
      j.should include('"rot_theta":0.1')
      j.should include('"rot_x":0')
      j.should include('"rot_y":0')
      j.should include('"rot_z":-1')
    end
  end

  describe "#json_create" do
    it "returns linear from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Rotate","data":{"step_delay":1,"rot_theta":0.1,"rot_x":1,"rot_y":0,"rot_z":0}}'
      m = RJR.parse_json(j)

      m.class.should == Motel::MovementStrategies::Rotate
      m.step_delay.should == 1
      m.rot_theta.should == 0.1
      m.rot_x.should == 1
      m.rot_y.should == 0
      m.rot_z.should == 0
    end
  end

end # describe Rotate

end # Motel::MovementStrategies
