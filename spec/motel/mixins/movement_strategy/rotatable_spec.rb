# Rotatable Movement Strategy Mixin Specs
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Motel
module MovementStrategies
describe Rotatable do
  let(:ms)  { Object.new.extend(Rotatable)}
  let(:loc) { Location.new }

  describe "#rot_dir" do
    it "returns rotation direction array" do
      ms.rot_x = 1
      ms.rot_y = 0
      ms.rot_z = 0
      ms.rot_dir.should == [1, 0, 0]
    end
  end

  describe "#rot_dir=" do
    it "sets movement direction array" do
      ms.rot_dir = [0, 1, 0]
      ms.rot_x.should == 0
      ms.rot_y.should == 1
      ms.rot_z.should == 0

      ms.rot_dir = 0.1, 0.2, 0.3
      ms.rot_x.should == 0.1
      ms.rot_y.should == 0.2
      ms.rot_z.should == 0.3
    end
  end

  describe "#init_rotation" do
    it "initializes rot_theta" do
      ms.init_rotation :rot_theta => Math::PI
      ms.rot_theta.should == Math::PI
    end

    it "initializes rot direction" do
      ms.init_rotation :rot_x => 0,
                       :rot_y => 1,
                       :rot_z => 0
      ms.rot_dir.should == [0, 1, 0]
    end

    it "initializes stop_angle" do
      ms.init_rotation :stop_angle => Math::PI/2
      ms.stop_angle.should == Math::PI/2
    end
  end

  describe "#valid_rotation?" do
    before(:each) do
      ms.rot_theta = 0.1
      ms.rot_dir = [0, 0, 1]
    end

    context "rot_theta is not numeric" do
      it "returns false" do
        ms.rot_theta = :a
        ms.valid_rotation?.should be_false
      end
    end

    context "rot_theta is out of bounds" do
      it "returns false" do
        ms.rot_theta = 20
        ms.valid_rotation?.should be_false
      end
    end

    context "rot dir is not numeric" do
      it "return false" do
        ms.rot_x = :a
        ms.valid_rotation?.should be_false

        ms.rot_x = 0
        ms.rot_y = :a
        ms.valid_rotation?.should be_false

        ms.rot_y = 0
        ms.rot_z = :a
        ms.valid_rotation?.should be_false
      end
    end

    context "rot dir is not normalized" do
      it "returns false" do
        ms.rot_x = 50
        ms.valid_rotation?.should be_false
      end
    end

    it "returns true" do
      ms.valid_rotation?.should be_true
    end
  end

  describe "#change_due_to_rotation" do
    context "stop_angle is nil" do
      it "returns false" do
        ms.change_due_to_rotation?(loc).should be_false
      end
    end

    context "loc.angle_rotated < stop_angle" do
      it "returns false" do
        loc.angle_rotated = 0.1
        ms.stop_angle = 0.2
        ms.change_due_to_rotation?(loc).should be_false
      end
    end

    context "loc.angle_rotated >= stop_angle" do
      it "returns true" do
        loc.angle_rotated = 0.2
        ms.stop_angle = 0.1
        ms.change_due_to_rotation?(loc).should be_true
      end
    end
  end

  describe "#will_rotate_past_stop" do
    context "stop angle is nil" do
      it "returns false" do
        ms.will_rotate_past_stop?(loc, 2*Math::PI).should be_false
      end
    end

    context "angle_rotated + angle <= stop_angle" do
      it "returns false" do
        ms.stop_angle = 0.3
        loc.angle_rotated = 0.1
        ms.will_rotate_past_stop?(loc, 0.1).should be_false
      end
    end

    context "angle_rotated + angle > stop_angle" do
      it "returns true" do
        ms.stop_angle = 0.2
        loc.angle_rotated = 0.1
        ms.will_rotate_past_stop?(loc, 0.2).should be_true

        ms.stop_angle = 0.2
        loc.angle_rotated = 0.1
        ms.will_rotate_past_stop?(loc, -0.2).should be_true
      end
    end
  end

  describe "#rotate" do
    it "applies rotation to location orientation over specified time" do
      loc.angle_rotated = 0
      loc.orientation   = 0.5121475197315839, -0.3841106397986879, -0.7682212795973759
      ms.rot_theta      = 0.40866086213858177
      ms.rot_dir        = -0.1414213562373095, 0.9899494936611665, 0.0
      expected          = [0.48070335596499597, -0.3886026631939148, -0.7860739492710513]

      ms.rotate(loc, 0.1)
      loc.orientation.should == expected
    end

    context "will exceed stop_angle" do
      it "reduces rotation to stop at stop_angle" do
        loc.angle_rotated = 0
        loc.orientation   = 0, 1, 0
        ms.rot_theta      = Math::PI/2
        ms.rot_dir        = 0, 0, 1
        ms.stop_angle     = Math::PI/4
        expected          = [-0.7071067811865475, 0.7071067811865476, 0.0]

        ms.rotate(loc, 1)
        loc.orientation.should == expected
      end
    end

    it "updates loc.angle_rotated" do
      loc.angle_rotated = 0.2
      loc.orientation   = -0.20628424925175867, -0.928279121632914, -0.309426373877638
      ms.rot_theta      =  0.706079093959504
      ms.rot_dir        = -0.5773502691896257, -0.5773502691896257, 0.5773502691896257 
      expected          =  0.2706079093959504

      ms.rotate(loc, 0.1)
      loc.angle_rotated.should == expected
    end

    it "returns location orientaiton" do
      loc.angle_rotated = 0
      loc.orientation   = -0.7715167498104595,  0.6172133998483676, -0.1543033499620919
      ms.rot_theta      =  0.7503533711007836
      ms.rot_dir        =  0.6461623427559643, -0.5743665268941905, -0.5025707110324167
      expected          = -0.7408582861619952,  0.653271396833327,  -0.15609446468259155

      ms.rotate(loc, 0.1).should == expected
    end
  end

  describe "#rot_to_s" do
    it "returns rotation in string format" do
      ms.rot_theta = Math::PI/4
      ms.rot_dir   = [0.0123, 1.1112, 0.936]
      ms.rot_to_s.should == "#{0.79}/#{0.01}/#{1.11}/#{0.94}"
    end
  end

  describe "#rotation_json" do
    it "returns rotation json data hash" do
      ms.rotation_json.should be_an_instance_of(Hash)
    end

    it "returns rot_theta in rotation json data hash" do
      ms.rot_theta = Math::PI
      ms.rotation_json[:rot_theta].should == Math::PI
    end

    it "returns rot dir in rotation json data hash" do
      ms.rot_dir = [0.1, 0.8, 0.2]
      ms.rotation_json[:rot_x].should == 0.1
      ms.rotation_json[:rot_y].should == 0.8
      ms.rotation_json[:rot_z].should == 0.2
    end

    it "returns stop_angle in rotation json data hash" do
      ms.stop_angle = 0.66
      ms.rotation_json[:stop_angle].should == 0.66
    end
  end
end # describe Rotatable
end # module MovementStrategies
end # module Motel
