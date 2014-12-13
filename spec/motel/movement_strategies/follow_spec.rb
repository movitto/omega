# Follow Movement Strategy unit tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/follow'

module Motel::MovementStrategies
describe Follow do
  let(:follow)  { Follow.new }
  let(:linear)  { Linear.new }
  let(:stopped) { Stopped.instance }
  let(:loc)     { build(:location) }
  let(:tracked) { build(:location) }

  describe "#init_orbit" do
    it "initializes elliptical axis" do
      axis = {:dmajx =>  Motel::MAJOR_CARTESIAN_AXIS[0],
              :dmajy =>  Motel::MAJOR_CARTESIAN_AXIS[1],
              :dmajz =>  Motel::MAJOR_CARTESIAN_AXIS[2],
              :dminx =>  Motel::CARTESIAN_NORMAL_VECTOR[0],
              :dminy =>  Motel::CARTESIAN_NORMAL_VECTOR[1],
              :dminz => -Motel::CARTESIAN_NORMAL_VECTOR[2]}
      follow.should_receive(:axis_from_args).with(axis)
      follow.init_orbit
    end

    it "initializes elliptical path" do
      follow.distance = 50000
      follow.should_receive(:path_from_args).with({:e => 0, :p => follow.distance})
      follow.init_orbit
    end
  end

  describe "#center" do
    it "returns tracked location coordinates" do
      follow.tracked_location = tracked
      follow.center.should == tracked.coordinates
    end

    context "tracked location not set" do
      it "returns origin" do
        follow.center.should == [0, 0, 0]
      end
    end
  end

  describe "#initialize" do
    let(:args)         { {:ar => :gs} }
    let(:default_args) { {:orientation_tolerance => Math::PI/32}.merge(args) }

    it "initializes target" do
      Follow.new(:target => tracked).target.should == tracked
    end

    it "initializes linear attributes" do
      Follow.test_new(args) { |ms| ms.should_receive(:linear_attrs_from_args).with(default_args) }
    end

    it "initializes trackable attributes" do
      Follow.test_new(args) { |ms| ms.should_receive(:trackable_attrs_from_args).with(default_args) }
    end

    it "initializes rotation" do
      Follow.test_new(args) { |ms| ms.should_receive(:init_rotation).with(default_args) }
    end

    it "initializes orbit" do
      Follow.test_new(args) { |ms| ms.should_receive(:init_orbit) }
    end

    it "sets step delay" do
      Follow.new(:step_delay => 5).step_delay.should == 5
    end

    it "sets defaults" do
      follow.target.should be_nil
      follow.orientation_tolerance.should == Math::PI/32
      follow.step_delay.should == 0.01
    end
  end

  describe "#valid?" do
    before(:each) do
      follow.speed = 50
      follow.tracked_location = tracked
      follow.distance = 0.1
    end

    context "tracked attributes not valid" do
      it "returns false" do
        follow.should_receive(:tracked_attrs_valid?).and_return(false)
        follow.should_not be_valid
      end
    end

    context "speed not valid" do
      it "returns false" do
        follow.should_receive(:speed_valid?).and_return(false)
        follow.should_not be_valid
      end
    end

    it "returns true" do
      follow.should be_valid
    end
  end

  describe "#move" do
    before(:each) do
      follow.tracked_location = tracked
      follow.distance = 50
      follow.speed = 20
      follow.init_orbit
    end

    context "follow is not valid" do
      it "does not move location" do
        follow.should_receive(:valid?).and_return(false)
        follow.should_not_receive(:move_linear)
        lambda { follow.move loc, 1 }.should_not change(loc, :coordinates)
      end
    end

    context "tracked location is nil" do
      it "does not move location" do
        follow.should_receive(:has_tracked_location?).and_return(false)
        follow.should_not_receive(:move_linear)
        lambda { follow.move loc, 1 }.should_not change(loc, :coordinates)
      end
    end

    context "tracked location has different parent" do
      it "does not move location" do
        loc.parent     = build(:location)
        tracked.parent = build(:location)
        follow.tracked_location = tracked
        follow.should_not_receive(:move_linear)
        lambda { follow.move loc, 1 }.should_not change(loc, :coordinates)
      end
    end

    context "target is moving" do
      before(:each) do
        linear.speed = 20
        tracked.ms = linear
      end

      context "not facing target" do
        before(:each) do
          follow.should_receive(:facing_target?)
                .with(loc).and_return(false)
        end

        it "faces target" do
          follow.should_receive(:face_target).with(loc)
          follow.move(loc, 1)
        end

        it "rotates location" do
          follow.should_receive(:rotate).with(loc, 1)
          follow.move(loc, 1)
        end

        it "updates acceleration from loc orientation" do
          follow.should_receive(:update_acceleration_from).with(loc)
          follow.move(loc, 1)
        end
      end

      it "moves location linearily" do
        follow.should_receive(:move_linear)
        follow.move(loc, 1)
      end

      context "slower target & within follow distance" do
        it "reduces speed to match target" do
          tracked.ms.speed = follow.speed / 2
          loc.coordinates = (tracked + [10, 0, 0]).coordinates
          follow.should_receive(:move_linear).with { follow.speed.should == tracked.ms.speed }
          follow.move(loc, 1)
        end
      end

      context "slower target & not within follow distance" do
        it "does not reduce speed" do
          speed = follow.speed
          tracked.ms.speed = follow.speed / 2
          loc.coordinates = (tracked + [1000, 0, 0]).coordinates
          follow.should_receive(:move_linear).with { follow.speed.should == speed }
          follow.move(loc, 1)
        end
      end
    end

    context "target is not moving" do
      before(:each) do
        tracked.ms = stopped
      end

      it "faces nearest coordinate on elliptical-path + an angular offset" do
        target = [100, -100, 100]
        follow.should_receive(:theta)
              .with(loc).and_return(Math::PI)
        follow.should_receive(:coordinates_from_theta)
              .with(7 * Math::PI / 6).and_return(target)
        follow.should_receive(:face_target).with(loc, target)
        follow.move loc, 1
        follow.target.should == target
      end

      it "rotates location" do
        follow.should_receive(:rotate).with(loc, 1)
        follow.move loc, 1
      end

      it "updates acceleration from loc orientation" do
        follow.should_receive(:update_acceleration_from).with(loc)
        follow.move loc, 1
      end

      it "moves location linearily" do
        follow.should_receive(:move_linear).with(loc, 1)
        follow.move loc, 1
      end
    end
  end

  describe "#to_json" do
    it "returns follow in json format" do
      m = Follow.new :step_delay          => 20,
                     :tracked_location_id =>  1,
                     :distance            =>  22,
                     :rot_theta           => 5.14,
                     :rot_x               => -1,
                     :rot_y               =>  0,
                     :rot_z               =>  0,
                     :speed               => 15,
                     :max_speed           => 50,
                     :dx                  =>  1,
                     :dz                  =>  0,
                     :dz                  =>  0,
                     :ax                  =>  0,
                     :ay                  =>  1,
                     :az                  =>  0,
                     :acceleration        => 90

      j = m.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Follow"')
      j.should include('"step_delay":20')
      j.should include('"tracked_location_id":1')
      j.should include('"distance":22')
      j.should include('"speed":15')
      j.should include('"max_speed":50')
      j.should include('"dx":1')
      j.should include('"dy":0')
      j.should include('"dz":0')
      j.should include('"ax":0')
      j.should include('"ay":1')
      j.should include('"az":0')
      j.should include('"acceleration":90')
      j.should include('"rot_theta":5.14')
      j.should include('"rot_x":-1')
      j.should include('"rot_y":0')
      j.should include('"rot_z":0')
      j.should include('"e":0')
      j.should include('"p":22')
    end
  end

  describe "#json_create" do
    it "returns follow from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Follow","data":{"speed":15,"tracked_location_id":1,"distance":22,"step_delay":20}}'
      m = RJR::JSONParser.parse(j)

      m.class.should == Motel::MovementStrategies::Follow
      m.step_delay.should == 20
      m.speed.should == 15
      m.tracked_location_id.should == 1
      m.distance.should == 22
    end
  end
end # describe Follow
end # module Motel::MovementStategies
