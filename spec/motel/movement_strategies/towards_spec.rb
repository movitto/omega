# Towards Movement Strategy unit tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/towards'

module Motel::MovementStrategies
describe Towards do
  let(:towards) { Towards.new }
  let(:loc)     { build(:location) }
  let(:target)  { Motel::Location.random.coordinates } 

  describe "#initialize" do
    it "initializes arriving state" do
      Towards.new(:arriving => true).arriving.should be_true
    end

    it "initializes linear attrs from args" do
      args = {:ar => :gs }
      Towards.test_new(args) { |ms| ms.should_receive(:linear_attrs_from_args).with(args) }
    end

    it "initializes rotation" do
      args = {:ar => :gs }
      Towards.test_new(args) { |ms| ms.should_receive(:linear_attrs_from_args).with(args) }
    end

    it "initializes target attrs from args" do
      args = {:ar => :gs }
      Towards.test_new(args) { |ms| ms.should_receive(:target_attrs_from_args).with(args) }
    end

    it "initializes step_delay" do
      Towards.new(:step_delay => 5).step_delay.should == 5
    end

    it "sets defaults" do
      towards.arriving.should be_false
      towards.step_delay.should == 0.01
    end

    it "sets distance tolerance" do
      speed = 500
      expected = 10 ** (speed.zeros-1)
      Towards.new(:max_speed => speed).distance_tolerance.should == expected
    end

    it "sets stop_near target" do
      target   = [   100, 200, -100]
      expected = [0, 100, 200, -100]
      Towards.new(:target => target).stop_near.should == expected
    end
  end

  describe "#valid?" do
    context "target attributes not valid" do
      it "returns false" do
        towards.should_receive(:target_attrs_valid?).and_return(false)
        towards.should_not be_valid
      end
    end

    context "target attributes valid" do
      it "returns true" do
        towards.should_receive(:target_attrs_valid?).and_return(true)
        towards.should be_valid
      end
    end
  end

  describe "#change?" do
    context "arrived at target" do
      it "returns true" do
        towards.should_receive(:arrived?).with(loc).and_return(true)
        towards.change?(loc).should be_true
      end
    end

    context "did not arrive at target" do
      it "returns false" do
        towards.should_receive(:arrived?).with(loc).and_return(false)
        towards.change?(loc).should be_false
      end
    end
  end

  describe "#rotational_time" do
    it "returns times to rotate 180 degrees" do
      towards.rot_theta = -Math::PI / 9
      towards.rotational_time.should == 9
    end
  end

  describe "#rotational_distance" do
    it "returns linear distance location covers moving at speed for rotational time" do
      towards.speed = 50
      towards.rot_theta = 2*Math::PI
      towards.rotational_distance.should == 25
    end
  end

  describe "#linear_time" do
    it "returns time it will take to deaccelerate from current speed" do
      towards.speed = 100
      towards.acceleration = 25
      towards.linear_time.should == 4
    end
  end

  describe "#linear_distance" do
    it "returns distance location covers while deaccelerating to a stop" do
      towards.speed = 10
      towards.acceleration = 15
      towards.linear_distance.should == 0
    end
  end

  describe "#near_target?" do
    before(:each) do
      towards.speed = 90
      towards.acceleration = 10
      towards.rot_theta = Math::PI / 6
      towards.target = target
    end

    context "distance loc from target <= rotational distance + linear distance" do
      it "returns true" do
        loc.coordinates = target
        towards.near_target?(loc).should be_true
      end
    end

    context "distance loc from target > rotational distance + linear distance" do
      it "returns false" do
        loc.coordinates = target.collect { |c| c * 10000 }
        towards.near_target?(loc).should be_false
      end
    end
  end

  describe "#move" do
    before(:each) do
      towards.target = target

      towards.speed = 1
      towards.acceleration = 90
    end

    context "strategy not valid" do
      it "does not move location" do
        towards.should_receive(:valid?).and_return(false)
        towards.should_not_receive(:move_linear)
        towards.move(loc, 1)
      end
    end

    context "arriving mode" do
      it "rotates location" do
        towards.arriving = true
        towards.should_receive(:rotate).with(loc, 0.3)
        towards.move(loc, 0.3)
      end
    end

    context "near target" do
      before(:each) do
        towards.arriving = false
        towards.should_receive(:near_target?)
               .with(loc).and_return(true)
      end

      context "not arriving" do
        it "faces inverse of movement direction" do
          towards.should_receive(:face).with(loc, towards.dir.collect { |d| d * -1 })
          towards.move(loc, 0.3)
        end
      end

      it "rotates location" do
        towards.should_receive(:rotate).with(loc, 0.3)
        towards.move(loc, 0.3)
      end

      it "sets arriving true" do
        towards.move(loc, 1)
        towards.arriving.should be_true
      end
    end

    context "not arriving and not near target" do
      before(:each) do
        towards.arriving = false
        towards.should_receive(:near_target?)
               .with(loc).and_return(false)
      end

      it "faces target" do
        towards.should_receive(:face_target).with(loc)
        towards.move(loc, 1)
      end

      it "rotates location" do
        towards.should_receive(:rotate).with(loc, 0.4)
        towards.move(loc, 0.4)
      end

      it "sets arriving false" do
        towards.move(loc, 0.4)
        towards.arriving.should be_false
      end

      context "facing direction of movement" do
        it "sets velocity directly from location orientation" do
          towards.should_receive(:facing_movement?)
                 .with(loc, towards.orientation_tolerance)
                 .and_return(true)
          towards.should_receive(:update_dir_from).with(loc)
          towards.move(loc, 1)
        end
      end
    end

    context "location rotating" do
      it "kills acceleration" do
        speed = towards.speed
        towards.should_receive(:rotation_stopped?)
               .with(loc).and_return(false)
        towards.move(loc, 1)
        towards.speed.should == speed
      end
    end

    it "updates acceleration direction from location orientation" do
      towards.should_receive(:update_acceleration_from).with(loc)
      towards.move(loc, 1)
    end

    it "moves location linearily" do
      towards.should_receive(:move_linear).with(loc, 1)
      towards.move(loc, 1)
    end
    
    context "location arrived at target" do
      it "sets location's coordinates to target" do
        towards.should_receive(:arrived?).with(loc).and_return(true)
        towards.move(loc, 1)
        loc.coordinates.should == target
      end
    end
  end

  describe "#to_json" do
    it "returns towards strategy in json format" do
      towards = Towards.new :step_delay            => 1,
                            :arriving              => true,
                            :target                => target,
                            :orientation_tolerance => Math::PI/8,
                            :rot_theta             => Math::PI/3,
                            :rot_x                 => 0,
                            :roy_y                 => 0,
                            :rot_z                 => 1,
                            :stop_angle            => Math::PI,
                            :speed                 => 57,
                            :dx                    => -1,
                            :dy                    =>  0,
                            :dz                    =>  0,
                            :ax                    =>  0,
                            :ay                    =>  0,
                            :az                    => -1,
                            :acceleration          => 12,
                            :stop_distance         => 25,
                            :max_speed             => 90
      j = towards.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Towards"')
      j.should include('"step_delay":1')
      j.should include('"arriving":true')
      j.should include('"target":'+target.to_json)
      j.should include('"orientation_tolerance":' + (Math::PI/8).to_s)
      j.should include('"rot_theta":' + (Math::PI/3).to_s)
      j.should include('"rot_x":0')
      j.should include('"rot_y":0')
      j.should include('"rot_z":1')
      j.should include('"stop_angle":'+Math::PI.to_s)
      j.should include('"speed":57')
      j.should include('"dx":-1')
      j.should include('"dy":0')
      j.should include('"dz":0')
      j.should include('"ax":0')
      j.should include('"ay":0')
      j.should include('"az":-1')
      j.should include('"acceleration":12')
      j.should include('"stop_distance":25')
      j.should include('"max_speed":90')
    end
  end

  describe "#json_create" do
    it "returns towards from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Towards","data":{"step_delay":1,"arriving":true,"target":[0.22396658352754284,-0.44032707899348655,-0.3119409189817083],"orientation_tolerance":0.39269908169872414,"distance_tolerance":1,"rot_theta":1.0471975511965976,"rot_x":0,"rot_y":0,"rot_z":1,"stop_angle":3.141592653589793,"speed":57,"dx":-1.0,"dy":0.0,"dz":0.0,"ax":0.0,"ay":0.0,"az":-1.0,"acceleration":12,"stop_distance":25,"stop_near":[0,0.22396658352754284,-0.44032707899348655,-0.3119409189817083],"max_speed":90}}'
      m = RJR::JSONParser.parse(j)

      m.class.should == Motel::MovementStrategies::Towards
      m.step_delay.should == 1
      m.arriving.should be_true
      m.target.should == [0.22396658352754284,-0.44032707899348655,-0.3119409189817083]
      m.orientation_tolerance.should == 0.39269908169872414
      m.rot_theta.should == 1.0471975511965976
      m.rot_dir.should == [0, 0, 1]
      m.stop_angle.should == Math::PI
      m.speed.should == 57
      m.dir.should == [-1, 0, 0]
      m.adir.should == [0, 0, -1]
      m.acceleration.should == 12
      m.stop_distance.should == 25
      m.max_speed.should == 90
    end
  end
end # describe Figure8
end # module Motel::MovementStrategies
