# Linear Movement Strategy unit tests
#
# Copyright (C) 2009-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/linear'

module Motel::MovementStrategies
describe Linear do
  let(:linear) { Linear.new }
  let(:loc)    { build(:location) }

  describe "#initialize" do
    it "initializes linear attributes" do
      args = {:att => :rs}
      Linear.test_new(args) { |ms| ms.should_receive(:linear_attrs_from_args).with(args) }
    end

    it "initializes rotation" do
      args = {:att => :rs}
      Linear.test_new(args) { |ms| ms.should_receive(:init_rotation).with(args) }
    end

    it "initializes dorientation" do
      ms = Linear.new :dorientation => true
      ms.dorientation.should be_true
    end

    it "initializes acceleration" do
      ms = Linear.new :dacceleration => true
      ms.dacceleration.should be_true
    end

    it "sets step delay" do
      ms = Linear.new :step_delay => 5
      ms.step_delay.should == 5
    end

    it "sets defaults" do
      linear.dorientation.should be_false
      linear.dacceleration.should be_false
      linear.step_delay.should == 0.01
    end
  end

  describe "#valid?" do
    before(:each) do
      linear.speed = 50
    end

    context "linear attrs not valid" do
      it "returns false" do
        linear.should_receive(:linear_attrs_valid?).and_return(false)
        linear.should_not be_valid
      end
    end

    context "rotation is not valid" do
      it "returns false" do
        linear.should_receive(:valid_rotation?).and_return(false)
        linear.should_not be_valid
      end
    end

    it "returns true" do
      linear.should be_valid
    end
  end

  describe "#change?" do
    context "stop distance exceeded" do
      it "returns true" do
        linear.should_receive(:stop_distance_exceeded?)
              .with(loc)
              .and_return(true)
        linear.change?(loc).should be_true
      end
    end

    context "stop distance not exceeded" do
      it "returns false" do
        linear.should_receive(:stop_distance_exceeded?)
              .with(loc)
              .and_return(false)
        linear.change?(loc).should be_false
      end
    end
  end

  describe "#move" do
    before(:each) do
      linear.speed = 50
    end

    context "linear not valid" do
      it "does not move location" do
        linear.should_receive(:valid?).and_return(false)
        linear.should_not_receive(:rotate)
        linear.should_not_receive(:move_linear)
        lambda { linear.move loc, 1 }.should_not change(loc, :coordinates)
      end
    end

    it "rotates location" do
      linear.should_receive(:rotate).with(loc, 1)
      linear.move(loc, 1)
    end

    it "moves location" do
      linear.should_receive(:move_linear).with(loc, 1)
      linear.move(loc, 1)
    end

    context "dorientation is true" do
      it "updates direction from location orientation" do
        linear.dorientation = true
        linear.should_receive(:update_dir_from).with(loc)
        linear.move(loc, 1)
      end
    end

    context "dacceleration is true" do
      it "updates acceleration from location orientation" do
        linear.dacceleration = true
        linear.should_receive(:update_acceleration_from).with(loc)
        linear.move(loc, 1)
      end
    end
  end

  describe "#to_json" do
    it "returns linear in json format" do
      m = Linear.new :step_delay    => 20,
                     :speed         => 15,
                     :max_speed     => 50,
                     :dx            =>  1,
                     :dz            =>  0,
                     :dz            =>  0,
                     :ax            =>  0,
                     :ay            =>  1,
                     :az            =>  0,
                     :acceleration  => 90,
                     :stop_distance => 150,
                     :stop_near     => [10, 0, 0, 1000],
                     :rot_theta     => 5.14,
                     :rot_x         => -1,
                     :rot_y         =>  0,
                     :rot_z         =>  0,
                     :stop_angle    => 5.15,
                     :dorientation  => true,
                     :dacceleration => true

      j = m.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Linear"')
      j.should include('"step_delay":20')
      j.should include('"speed":15')
      j.should include('"max_speed":50')
      j.should include('"dx":1')
      j.should include('"dy":0')
      j.should include('"dz":0')
      j.should include('"ax":0')
      j.should include('"ay":1')
      j.should include('"az":0')
      j.should include('"acceleration":90')
      j.should include('"stop_distance":150')
      j.should include('"stop_near":[10,0,0,1000]')
      j.should include('"rot_theta":5.14')
      j.should include('"rot_x":-1')
      j.should include('"rot_y":0')
      j.should include('"rot_z":0')
      j.should include('"stop_angle":5.15')
      j.should include('"dorientation":true')
      j.should include('"dacceleration":true')
    end
  end

  describe "#json_create" do
    it "returns linear from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Linear","data":{"speed":15,"stop_distance":150,"dx":1,"dy":0,"step_delay":20,"dz":0,"rot_theta":5.14,"rot_x":-1,"rot_y":0,"rot_z":0}}'
      m = RJR::JSONParser.parse(j)

      m.class.should == Motel::MovementStrategies::Linear
      m.step_delay.should == 20
      m.speed.should == 15
      m.dx.should == 1
      m.dy.should == 0
      m.dz.should == 0
      m.rot_theta.should == 5.14
      m.rot_x.should == -1
      m.rot_y.should == 0
      m.rot_z.should == 0
      m.stop_distance.should == 150
    end
  end
end # describe Linear
end # module Motel::MovementStrategies
