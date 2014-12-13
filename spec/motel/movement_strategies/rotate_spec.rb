# Rotate Movement Strategy unit tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/location'
require 'motel/movement_strategies/rotate'

module Motel::MovementStrategies
describe Rotate do
  let(:rot) { Rotate.new   }
  let(:loc) { build(:location) }

  describe "#initialize" do
    it "initializes rotation" do
      args = {:ar => :gs}
      Rotate.test_new(args) { |ms| ms.should_receive(:init_rotation).with(args) }
    end

    it "sets step delay" do
      Rotate.new(:step_delay => 5).step_delay.should == 5
    end

    it "sets defaults" do
      Rotate.new.step_delay.should == 0.01
    end
  end

  describe "#valid?" do
    context "valid rotation" do
      it "returns true" do
        rot.should_receive(:valid_rotation?).and_return(true)
        rot.should be_valid
      end
    end

    context "invalid rotation" do
      it "returns false" do
        rot.should_receive(:valid_rotation?).and_return(false)
        rot.should_not be_valid
      end
    end
  end

  describe "#change?" do
    context "change due to rotation" do
      it "returns true" do
        rot.should_receive(:change_due_to_rotation?).with(loc).and_return(true)
        rot.change?(loc).should be_true
      end
    end

    context "no change due to rotation" do
      it "returns false" do
        rot.should_receive(:change_due_to_rotation?).with(loc).and_return(false)
        rot.change?(loc).should be_false
      end
    end
  end

  describe "#rotate" do
    context "rotate is not valid" do
      it "does not rotate location" do
        rot.should_receive(:valid?).and_return(false)
        rot.should_not_receive(:rotate)
        lambda { rot.move loc, 5 }.should_not change(loc, :orientation)
      end
    end

    it "rotates location" do
      rot.should_receive(:rotate).with(loc, 1)
      rot.move loc, 1
    end
  end

  describe "#to_json" do
    it "returns rotate in json format" do
      rot = Rotate.new :rot_theta  => 0.1,
                       :step_delay => 1,
                       :rot_x      => 0,
                       :rot_y      => 0,
                       :rot_z      => -1,
                       :stop_angle => 0.33

      j = rot.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Rotate"')
      j.should include('"step_delay":1')
      j.should include('"rot_theta":0.1')
      j.should include('"rot_x":0')
      j.should include('"rot_y":0')
      j.should include('"rot_z":-1')
      j.should include('"stop_angle":0.33')
    end
  end

  describe "#json_create" do
    it "returns linear from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Rotate","data":{"step_delay":1,"rot_theta":0.1,"rot_x":1,"rot_y":0,"rot_z":0}}'
      m = RJR::JSONParser.parse(j)

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
