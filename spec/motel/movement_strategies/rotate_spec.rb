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

    context "dtheta is invalid" do
      it "returns false" do
        @r.dtheta = :foo
        @r.should_not be_valid
        @r.dtheta = -10.11
        @r.valid?.should be_false

        @r.dtheta = 9.89
        @r.valid?.should be_false
      end
    end

    context "dphi is nil" do
      it "returns false" do
        @r.dphi = :foo
        @r.valid?.should be_false

        @r.dphi = -10.11
        @r.valid?.should be_false

        @r.dphi = 10.22
        @r.valid?.should be_false

        @r.dtheta = -0.45
        @r.dphi   = 0.35
        @r.valid?.should be_true
      end
    end

    it "returns true" do
      @r.should be_valid
    end
  end

  describe "#rotate" do
    it "rotates location by dtheta / dphi * elapsed time" do
      rot = Rotate.new :speed => 5, :step_delay => 5, :dtheta => 0.11, :dphi => 0.22
      dt,dp  = rot.dtheta, rot.dphi

      p   = Motel::Location.new
      orientation  = [1,0,0]
      sorientation = Motel::to_spherical(*orientation)
      l = Motel::Location.new(:parent => p,
                              :movement_strategy => rot,
                              :orientation  => orientation)

      # move and validate
      rot.move l, 1
      l.orientation.should ==
        Motel.from_spherical(sorientation[0] + dt, sorientation[1] + dp, 1)

      orientation  = l.orientation
      sorientation = l.spherical_orientation

      rot.move l, 5
      l.orientation.should ==
        Motel.from_spherical(sorientation[0] + dt * 5, sorientation[1] + dp * 5, 1)
    end
  end

end # describe Rotatable

describe Rotate do
  describe "#initialize" do
    it "sets defaults" do
      r = Rotate.new
      r.dtheta.should == 0
      r.dphi.should == 0
    end

    it "sets arguments" do
      rot = Rotate.new :speed => 5, :dtheta => 0.25, :dphi => 0.56
      rot.dtheta = 0.25
      rot.dphi   = 0.56
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
        rot = Rotate.new :dtheta => -10
        l = build(:location)

        lambda {
          rot.move l, 5
        }.should_not change(l, :coordinates)
      end
    end
  end

  describe "#to_json" do
    it "returns rotate in json format" do
      rot = Rotate.new :dtheta => 0.1, :dphi => 0.2, :step_delay => 1

      j = rot.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Rotate"')
      j.should include('"step_delay":1')
      j.should include('"dtheta":0.1')
      j.should include('"dphi":0.2')
    end
  end

  describe "#json_create" do
    it "returns linear from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Rotate","data":{"step_delay":1,"dtheta":0.1,"dphi":0.2}}'
      m = JSON.parse(j)

      m.class.should == Motel::MovementStrategies::Rotate
      m.step_delay.should == 1
      m.dtheta.should == 0.1
      m.dphi.should == 0.2
    end
  end

end # describe Rotate

end # Motel::MovementStrategies
