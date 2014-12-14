# Figure8 Movement Strategy unit tests
#
# Copyright (C) 2009-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/figure8'

module Motel::MovementStrategies
describe Figure8 do
  let(:figure8) { Figure8.new }
  let(:loc)     { build(:location) }
  let(:tracked) { build(:location) }

  def modified_args(args)
    {:orientation_tolerance => Math::PI/64}.merge(args)
  end

  describe "#initialize" do
    it "initializes evading state" do
      Figure8.new(:evading => true).evading.should be_true
    end

    it "initializes orientation tolerance" do
      Figure8.new(:orientation_tolerance => Math::PI).orientation_tolerance.should == Math::PI
    end

    it "initializes linear attrs from args" do
      args = {:ar => :gs }
      modified = modified_args(args)
      Figure8.test_new(args) { |ms| ms.should_receive(:linear_attrs_from_args).with(modified) }
    end

    it "initializes trackable attributes from args" do
      args = {:ar => :gs }
      modified = modified_args(args)
      Figure8.test_new(args) { |ms| ms.should_receive(:trackable_attrs_from_args).with(modified) }
    end

    it "initializes rotation from args" do
      args = {:ar => :gs }
      modified = modified_args(args)
      Figure8.test_new(args) { |ms| ms.should_receive(:init_rotation).with(modified) }
    end

    it "initializes step_delay" do
      Figure8.new(:step_delay => 1).step_delay.should == 1
    end

    it "sets defaults" do
      figure8.evading.should be_false
      figure8.orientation_tolerance.should == Math::PI/64
      figure8.step_delay.should == 0.01
    end
  end

  describe "#valid?" do
    before(:each) do
      figure8.tracked_location = tracked
      figure8.distance = 100
      figure8.speed = 10
    end

    context "tracked attributes not valid" do
      it "returns false" do
        figure8.should_receive(:tracked_attrs_valid?).and_return(false)
        figure8.should_not be_valid
      end
    end

    context "speed not valid" do
      it "returns false" do
        figure8.should_receive(:speed_valid?).and_return(false)
        figure8.should_not be_valid
      end
    end

    it "returns true" do
      figure8.should be_valid
    end
  end

  describe "#move" do
    before(:each) do
      figure8.tracked_location = tracked
      figure8.distance = 10
      figure8.speed    = 50
      loc.parent = tracked.parent = build(:location)
    end

    context "strategy not valid" do
      it "does not move location" do
        figure8.should_receive(:valid?).and_return(false)
        figure8.should_not_receive(:move_linear)
        figure8.move(loc, 1)
      end
    end

    context "does not have tracked location" do
      it "does not move location" do
        figure8.should_receive(:has_tracked_location?).and_return(false)
        figure8.should_not_receive(:move_linear)
        figure8.move(loc, 1)
      end
    end

    context "loc and tracked loc have different parents" do
      it "does not move location" do
        figure8.should_receive(:same_system?).and_return(false)
        figure8.should_not_receive(:move_linear)
        figure8.move(loc, 1)
      end
    end

    context "not within tracking distance" do
      context "initial run" do
        # FIXME not possible, evading is never undefined!
        it "faces target"
      end

      context "when evading" do
        it "faces target" do
          figure8.evading = true
          figure8.should_receive(:near_target?).twice.and_return(false)
          figure8.should_receive(:face_target).with(loc)
          figure8.move(loc, 1)
        end
      end

      it "sets evading false" do
        figure8.evading = true
        figure8.should_receive(:near_target?).twice.and_return(false)
        figure8.move(loc, 1)
        figure8.evading.should be_false
      end
    end

    context "within tracking distance" do
      before(:each) do
        figure8.should_receive(:near_target?)
               .with(loc).once
               .and_return(true)
      end

      context "within evading distance" do
        before(:each) do
          figure8.should_receive(:near_target?)
                 .with(loc, figure8.distance/5).once
                 .and_return(true)
        end

        context "not evading" do
          before(:each) do
            figure8.evading = false
          end

          it "faces away from target at evading angle" do
            figure8.should_receive(:face_away_from_target).with(loc, Math::PI/4)
            figure8.move(loc, 1)
          end
        end

        it "sets evading true" do
          figure8.move(loc, 1)
          figure8.evading.should be_true
        end
      end

      context "not evading and not facing target" do
        before(:each) do
          figure8.should_receive(:near_target?)
                 .with(loc, figure8.distance/5).once
                 .and_return(false)

          figure8.should_receive(:facing_target?)
                 .with(loc).and_return(false)

          figure8.evading = false
        end

        it "faces target" do
          figure8.should_receive(:face_target).with(loc)
          figure8.move(loc, 1)
        end
      end
    end

    it "rotates location" do
      figure8.should_receive(:rotate).with(loc, 0.1)
      figure8.move(loc, 0.1)
    end

    context "invalid rotation" do
      it "does not rotate location" do
        figure8.should_receive(:valid_rotation?).and_return(false)
        figure8.should_not_receive(:rotate).with(loc, 0.1)
        figure8.move(loc, 0.1)
      end
    end
    
    it "updates acceleration from location orientation" do
      figure8.should_receive(:update_acceleration_from).with(loc)
      figure8.move(loc, 2)
    end

    context "not within tracking distance and not facing target" do
      it "cuts acceleration" do
        speed = figure8.speed
        figure8.should_receive(:near_target?)
               .twice.and_return(false)
        figure8.should_receive(:facing_target?)
               .and_return(false)
        figure8.move(loc, 1)
        figure8.speed.should == speed
      end
    end

    it "moves location linearily" do
      figure8.should_receive(:move_linear).with(loc, 1)
      figure8.move(loc, 1)
    end
  end

  describe "#to_json" do
    it "returns figure8 strategy in json format" do
      figure8 = Figure8.new :step_delay       => 0.2,
                            :evading          => true,
                            :tracked_location_id => tracked.id,
                            :distance         => 50,
                            :rot_theta        => 0.12,
                            :rot_x            => 0,
                            :rot_y            => 1,
                            :rot_z            => 0,
                            :stop_angle       => 1.22,
                            :speed            => 80,
                            :dx               => 1,
                            :dy               => 0,
                            :dz               => 0,
                            :ax               => -1,
                            :ay               =>  0,
                            :az               =>  0,
                            :acceleration     => 100,
                            :max_speed        => 200
      j = figure8.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Figure8"')
      j.should include('"step_delay":0.2')
      j.should include('"evading":true')
      j.should include('"tracked_location_id":'+tracked.id.to_s)
      j.should include('"distance":50')
      j.should include('"rot_theta":0.12')
      j.should include('"rot_x":0')
      j.should include('"rot_y":1')
      j.should include('"rot_z":0')
      j.should include('"stop_angle":1.22')
      j.should include('"speed":80')
      j.should include('"dx":1')
      j.should include('"dy":0')
      j.should include('"dz":0')
      j.should include('"ax":-1')
      j.should include('"ay":0')
      j.should include('"az":0')
      j.should include('"acceleration":100')
      j.should include('"max_speed":200')
    end
  end

  describe "#json_create" do
    it "returns figure8 from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Figure8","data":{"step_delay":0.2,"evading":true,"tracked_location_id":10003,"distance":50,"rot_theta":0.12,"rot_x":0,"rot_y":1,"rot_z":0,"stop_angle":1.22,"speed":80,"dx":1.0,"dy":0.0,"dz":0.0,"ax":-1.0,"ay":0.0,"az":0.0,"acceleration":100,"stop_distance":null,"stop_near":null,"max_speed":200}}'
      m = RJR::JSONParser.parse(j)

      m.class.should == Motel::MovementStrategies::Figure8
      m.step_delay.should == 0.2
      m.evading.should be_true
      m.tracked_location_id.should == 10003
      m.distance.should == 50
      m.rot_theta.should == 0.12
      m.rot_dir.should == [0, 1, 0]
      m.stop_angle.should == 1.22
      m.speed.should == 80
      m.dir.should == [1, 0, 0]
      m.adir.should == [-1, 0, 0]
      m.acceleration.should == 100
      m.max_speed.should == 200
    end
  end
end # describe Figure8
end # module Motel::MovementStrategies
