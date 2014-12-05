# Motel Math Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Motel
  describe "#length" do
    it "returns length of specified vector" do
      Motel.length(0, 0, 0).should == 0
      Motel.length(10, 0, 0).should == 10
      Motel.length(10, 10, 0).should == 14.142135623730951
      Motel.length(10, 10, 100).should == 100.99504938362078
    end
  end
  
  describe "#normalize" do
    it "returns a new vector" do
      v = [1,0,0]
      v1 = Motel.normalize *v
      v1.should_not equal(v)
    end
  
    context "vector is normalized" do
      it "returns self" do
        [[1,0,0], [0,1,0], [0,0,1]].each { |v|
          v1 = Motel.normalize *v
          v1.should == v
        }
      end
    end
  
    context "vector is invalid" do
      it "raises an ArgumentError" do
        lambda{
          Motel.normalize 0,0,0
        }.should raise_error(ArgumentError)
      end
    end
  
    it "returns normalized vector" do
      x,y,z = Motel.normalize 0.5,0.5,0.5
      x.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.577350269189626)
      y.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.577350269189626)
      z.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.577350269189626)
  
      x,y,z = Motel.normalize 0.75,0.6,0.12
      x.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.77484465921718)
      y.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.619875727373744)
      z.should be_within(OmegaTest::CLOSE_ENOUGH).of(0.123975145474749)
    end
  end
  
  describe "#normalized?" do
    context "vector is normalized" do
      it "returns true" do
        Motel.normalized?(0, 0, 1).should be_true
      end
    end
  
    context "vector is not normalized" do
      it "returns false" do
        Motel.normalized?(1, 1, 1).should be_false
        Motel.normalized?(0, 0, 0).should be_false
        Motel.normalized?(0.5, 0.5, 0.5).should be_false
      end
    end
  end
  
  describe "#cross_product" do
    it "return cross product between vectors" do
      Motel.cross_product(2,3,4,7,6,5).should == [-9,18,-9]
      Motel.cross_product(62,-32,147,-19,-19,3).should == [2697,-2979,-1786]
      Motel.cross_product(0.75,0.11,1.33,-1.3,0.58,0.01).should == [-0.7703,-1.7365000000000002,0.578]
    end
  end
  
  describe "#dot_product" do
    it "returns dot product of vectors" do
      Motel.dot_product(2,3,4,7,6,5).should == 52
      Motel.dot_product(62,-32,147,-19,-19,3).should == -129
      Motel.dot_product(0.75,0.11,1.33,-1.3,0.58,0.01).should == -0.8979000000000001
    end
  end
  
  describe "#angle_between" do
    it "returns the angle between vectors" do
      Motel.angle_between(2,3,4,5,6,7).should == 0.1304771607247696
      Motel.angle_between(62,-32,147,-19,-19,3).should == 1.6001227358204873
      Motel.angle_between(0.75,0.11,1.33,-1.3,0.58,0.01).should == 1.995470250041254
      Motel.angle_between(1, 1, 1, -1, -1, -1).should == Math::PI
      Motel.angle_between(42, 42, 42, 42, 42, 42).should == 0
      Motel.angle_between(1, 0, 0, 0, 0, 1).should == Math::PI / 2
      Motel.angle_between(1, 0, 0, 0, 0, -1).should == Math::PI / 2
      Motel.angle_between(-1, 0, 0, 0, 0, 1).should == Math::PI / 2
      Motel.angle_between(0.1, 0, 0, 0, 0.2, 0).should == Math::PI / 2
      Motel.angle_between(0.1, 0, 0, -0.1, 0.2, 0).should == 2.0344439357957027
      Motel.angle_between(-0.1, 0.2, 0, 0.1, 0, 0).should == 2.0344439357957027
    end
  
    context "invalid parameters" do
      it "raises argument error" do
        lambda{
          Motel.angle_between(0, 0, 0, 1, 0, 0)
        }.should raise_error(ArgumentError)
  
        lambda{
          Motel.angle_between(1, 0, 0, 0, 0, 0)
        }.should raise_error(ArgumentError)
      end
    end
  end
  
  describe "#axis_angle" do
    it "returns the axis angle between two vectors" do
      Motel.axis_angle( 1,  0,  0,  0,  1,  0).should == [Math::PI/2,  0,  0,  1]
      Motel.axis_angle( 1,  0,  0,  0, -1,  0).should == [Math::PI/2,  0,  0, -1]
      Motel.axis_angle( 1,  0,  0,  0,  0,  1).should == [Math::PI/2,  0, -1,  0]
      Motel.axis_angle( 1,  0,  0,  0,  0, -1).should == [Math::PI/2,  0,  1,  0]
      Motel.axis_angle(-1,  0,  0,  0,  1,  0).should == [Math::PI/2,  0,  0, -1]
      Motel.axis_angle(-1,  0,  0,  0, -1,  0).should == [Math::PI/2,  0,  0,  1]
      Motel.axis_angle(-1,  0,  0,  0,  0,  1).should == [Math::PI/2,  0,  1,  0]
      Motel.axis_angle(-1,  0,  0,  0,  0, -1).should == [Math::PI/2,  0, -1,  0]
      Motel.axis_angle( 0,  1,  0,  0,  0,  1).should == [Math::PI/2,  1,  0,  0]
      Motel.axis_angle( 0,  1,  0,  0,  0, -1).should == [Math::PI/2, -1,  0,  0]
      Motel.axis_angle( 0, -1,  0,  0,  0,  1).should == [Math::PI/2, -1,  0,  0]
      Motel.axis_angle( 0, -1,  0,  0,  0, -1).should == [Math::PI/2,  1,  0,  0]
  
      Motel.axis_angle( 0,  1,  0,  1,  0,  0).should == [Math::PI/2,  0,  0, -1]
      Motel.axis_angle( 0, -1,  0,  1,  0,  0).should == [Math::PI/2,  0,  0,  1]
      Motel.axis_angle( 0,  0,  1,  1,  0,  0).should == [Math::PI/2,  0,  1,  0]
      Motel.axis_angle( 0,  0, -1,  1,  0,  0).should == [Math::PI/2,  0, -1,  0]
  
      Motel.axis_angle( 0,  1,  0, -1,  0,  0).should == [Math::PI/2,  0,  0,  1]
      Motel.axis_angle( 0, -1,  0, -1,  0,  0).should == [Math::PI/2,  0,  0, -1]
      Motel.axis_angle( 0,  0,  1, -1,  0,  0).should == [Math::PI/2,  0, -1,  0]
      Motel.axis_angle( 0,  0, -1, -1,  0,  0).should == [Math::PI/2,  0,  1,  0]
      Motel.axis_angle( 0,  0,  1,  0,  1,  0).should == [Math::PI/2, -1,  0,  0]
      Motel.axis_angle( 0,  0, -1,  0,  1,  0).should == [Math::PI/2,  1,  0,  0]
      Motel.axis_angle( 0,  0,  1,  0, -1,  0).should == [Math::PI/2,  1,  0,  0]
      Motel.axis_angle( 0,  0, -1,  0, -1,  0).should == [Math::PI/2, -1,  0,  0]
  
      Motel.axis_angle( 1,  0,  0, -1,  0,  0).should == [Math::PI,    0, -1,  0]
      Motel.axis_angle(-1,  0,  0,  1,  0,  0).should == [Math::PI,    0,  1,  0]
      Motel.axis_angle( 0,  1,  0,  0, -1,  0).should == [Math::PI,    1,  0,  0]
      Motel.axis_angle( 0, -1,  0,  0,  1,  0).should == [Math::PI,   -1,  0,  0]
      Motel.axis_angle( 0,  0,  1,  0,  0, -1).should == [Math::PI,    0,  1,  0]
      Motel.axis_angle( 0,  0, -1,  0,  0,  1).should == [Math::PI,    0, -1,  0]
  
      Motel.axis_angle( 1,  0,  0,  1,  0,  0).should == [0,  0, -1, 0]
      Motel.axis_angle( 0,  1,  0,  0,  1,  0).should == [0,  1,  0, 0]
      Motel.axis_angle( 0,  0,  1,  0,  0,  1).should == [0,  0,  1, 0]
      Motel.axis_angle(-1,  0,  0, -1,  0,  0).should == [0,  0,  1, 0]
      Motel.axis_angle( 0, -1,  0,  0, -1,  0).should == [0, -1,  0, 0]
      Motel.axis_angle( 0,  0, -1,  0,  0, -1).should == [0,  0, -1, 0]
  
      Motel.axis_angle(0.75,  0.75, 0.75, -0.75, -0.75, -0.75).should == [Math::PI,  0.7071067811865476, -0.7071067811865476, 0]
      Motel.axis_angle(0.75, -0.75, 0.75, -0.75,  0.75, -0.75).should == [Math::PI, -0.7071067811865476, -0.7071067811865476, 0]
      Motel.axis_angle(0.75, -0.75, 0.75,  0.75, -0.75,  0.75).should == [0, -0.7071067811865476, -0.7071067811865476, 0]
  
      Motel.axis_angle(10, 0, 0, 0, 20, 0).should == [Math::PI/2,  0,  0,  1]
      Motel.axis_angle(-1000, 0, 0, 0, 0, 500).should == [Math::PI/2,  0,  1,  0]
      Motel.axis_angle(-1000, 0, 0, 0, 0, 500).should == [Math::PI/2,  0,  1,  0]
  
      vec1 = [0.8507471196904255,  -0.6867482921589393,  -0.35611458624225456,]
      vec2 = [0.36580264586266187, -0.46516252520481505, -0.33282165134157504]
      expected = [0.28511318329351065, 0.2865138658283393, 0.696226417234539, -0.658163034994262]
      Motel.axis_angle(*vec1, *vec2).should == expected
  
      vec1 = [0.8507471196904255,  -0.6867482921589393,  -0.35611458624225456,]
      vec2 = [0.6195361097534338, -0.7878154642344266, -0.5636783479999417]
      expected = [0.28511318329351065, 0.28651386582833926, 0.696226417234539, -0.6581630349942618]
      Motel.axis_angle(*vec1, *vec2).should == expected
  
      vec1 = [0.2922769321258475, 0.8326274170434125, 0.6994760146295643]
      vec2 = [0.06311073043263427, 0.16040830061422096, -0.8253081775750845]
      expected = [2.035268996106137, -0.9417688616123677, 0.3361947085944239, -0.006673021089072138]
      Motel.axis_angle(*vec1, *vec2).should == expected
  
      vec1 = [0.01, 0.03, 0]
      vec2 = [-0.02, 0, 0.01]
      expected = [1.857552879006445, 0.44232586846469135, -0.14744195615489714, 0.8846517369293827]
      Motel.axis_angle(*vec1, *vec2).should == expected
    end
  
    it "returns axis orthogonal to input vectors" do
      vec1 = [0.038385973948795615, 0.6568970644551508, -0.8769998506005329]
      vec2 = [0.8917376542579171, -0.11961538238472191, 0.8461552223616393]
      result = Motel.axis_angle(*vec1, *vec2)
      Motel.orthogonal?(*vec1, *result[1..3]).should be_true
      Motel.orthogonal?(*vec2, *result[1..3]).should be_true
  
      vec1 = Motel::Location.random.coordinates
      vec2 = Motel::Location.random.coordinates
      result = Motel.axis_angle(*vec1, *vec2)
      Motel.orthogonal?(*vec1, *result[1..3]).should be_true
      Motel.orthogonal?(*vec2, *result[1..3]).should be_true
    end
  
    context "invalid parameters" do
      it "raises ArgumentError" do
        lambda{
          Motel.axis_angle( 1, 0, 0, 0, 0, 0)
        }.should raise_error(ArgumentError)
  
        lambda{
          Motel.axis_angle( 0, 0, 0, 1, 0, 0)
        }.should raise_error(ArgumentError)
      end
    end
  end
  
  describe "#rotate" do
    it "returns coordinate rotated around axis angle" do
      coord      = [0, 0, 1]
      expected   = [0, -1, 0]
      axis_angle = [Math::PI/2, 1, 0, 0]
      Motel.rotate(*coord, *axis_angle)
           .collect { |c| c.round_to(OmegaTest::CLOSE_PRECISION) }
           .should == expected
  
      coord      = [0, 0,  1]
      expected   = [0, 0, -1]
      axis_angle = [Math::PI, 0, -1, 0]
      Motel.rotate(*coord, *axis_angle)
           .collect { |c| c.round_to(OmegaTest::CLOSE_PRECISION) }
           .should == expected
  
      coord      = [0, 0,  1]
      expected   = [0, 0, 1]
      axis_angle = [2*Math::PI, 1, 0, 0]
      Motel.rotate(*coord, *axis_angle)
           .collect { |c| c.round_to(OmegaTest::CLOSE_PRECISION) }
           .should == expected
  
      coord      = [0, 1, 0]
      expected   = [0, 1, 0]
      axis_angle = [0, 0, 1, 0]
      Motel.rotate(*coord, *axis_angle)
           .collect { |c| c.round_to(OmegaTest::CLOSE_PRECISION) }
           .should == expected
  
      coord      = [0, 0.75, 0.33]
      expected   = [0, 0.75, 0.33]
      axis_angle = [Math::PI, 0, 0.75, 0.33]
      Motel.rotate(*coord, *axis_angle)
           .collect { |c| c.round_to(OmegaTest::CLOSE_PRECISION) }
           .should == expected
  
      coord      = [0, 0, 0]
      expected   = [0, 0, 0]
      axis_angle = [Math::PI, 0, 1, 0]
      Motel.rotate(*coord, *axis_angle)
           .collect { |c| c.round_to(OmegaTest::CLOSE_PRECISION) }
           .should == expected
  
      coord      = [0.8507471196904255,  -0.6867482921589393,  -0.35611458624225456]
      expected   = [0.6195361097534338, -0.7878154642344266, -0.5636783479999417]
      axis_angle = [0.28511318329351065, 0.2865138658283393, 0.696226417234539, -0.658163034994262]
      Motel.rotate(*coord, *axis_angle).should == expected
  
      coord      = [0.24384749360548985, 0.9863251626574024, -0.2362468669185284]
      expected   = [1.013113773733617, -0.24841752524313032, -0.0008505180537918822]
      axis_angle = [4*Math::PI/3, -0.6641823301543148, -0.28178996272731527, 0.6924277935040758]
      Motel.rotate(*coord, *axis_angle).should == expected
    end
  
    it "preserves length of original coordinate" do
      coord      = Motel.rand_vector
      axis_angle = [rand] + Motel.rand_vector
      result     = Motel.rotate(*coord, *axis_angle)
      (Motel.length(*coord) - Motel.length(*result)).abs.should < CLOSE_ENOUGH
    end
  
    context "invalid axis" do
      it "raises argument error" do
        lambda{
          Motel.rotate(0, 1, 0, Math::PI, 0, 0, 0)
        }.should raise_error(ArgumentError)
      end
    end
  end
  
  describe "#rotated_angle" do
    it "returns the angle component of the axis-angle specified by axis and new/old coordinates" do
      Motel.rotated_angle( 1,  0,  0,  0,  0,  1,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  0,  1,  1,  0,  0,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 1,  0,  0,  0,  0,  1,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0,  0,  1,  1,  0,  0,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle(-1,  0,  0,  0,  0,  1,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0,  0, -1,  1,  0,  0,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle(-1,  0,  0,  0,  0,  1,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  0, -1,  1,  0,  0,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 1,  0,  0,  0,  0, -1,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0,  0,  1, -1,  0,  0,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 1,  0,  0,  0,  0, -1,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  0,  1, -1,  0,  0,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
  
      Motel.rotated_angle( 1,  0,  0, -1,  0,  0,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle(-1,  0,  0,  1,  0,  0,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  0,  1,  0,  0, -1,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  0, -1,  0,  0,  1,  0,  1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 1,  0,  0, -1,  0,  0,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle(-1,  0,  0,  1,  0,  0,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  0,  1,  0,  0, -1,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  0, -1,  0,  0,  1,  0, -1,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
  
      Motel.rotated_angle( 0,  1,  0,  0,  0,  1,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0,  0,  1,  0,  1,  0,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  1,  0,  0,  0,  1, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  0,  1,  0,  1,  0, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0, -1,  0,  0,  0,  1,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  0, -1,  0,  1,  0,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0, -1,  0,  0,  0,  1, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0,  0, -1,  0,  1,  0, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  1,  0,  0,  0, -1,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  0,  1,  0, -1,  0,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0,  1,  0,  0,  0, -1, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0,  0,  1,  0, -1,  0, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
  
      Motel.rotated_angle( 0,  1,  0,  0, -1,  0,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0, -1,  0,  0,  1,  0,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  0,  1,  0,  0, -1,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  0, -1,  0,  0,  1,  1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  1,  0,  0, -1,  0, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0, -1,  0,  0,  1,  0, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  0,  1,  0,  0, -1, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  0, -1,  0,  0,  1, -1,  0,  0).should be_within(CLOSE_ENOUGH).of(  Math::PI)
  
      Motel.rotated_angle( 1,  0,  0,  0,  1,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0,  1,  0,  1,  0,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 1,  0,  0,  0,  1,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  1,  0,  1,  0,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle(-1,  0,  0,  0,  1,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0, -1,  0,  1,  0,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle(-1,  0,  0,  0,  1,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0, -1,  0,  1,  0,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 1,  0,  0,  0, -1,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
      Motel.rotated_angle( 0,  1,  0, -1,  0,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 1,  0,  0,  0, -1,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(3*Math::PI/2)
      Motel.rotated_angle( 0,  1,  0, -1,  0,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(  Math::PI/2)
  
      Motel.rotated_angle( 0,  1,  0,  0, -1,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0, -1,  0,  0,  1,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 1,  0,  0, -1,  0,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle(-1,  0,  0,  1,  0,  0,  0,  0,  1).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0,  1,  0,  0, -1,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 0, -1,  0,  0,  1,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle( 1,  0,  0, -1,  0,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(  Math::PI)
      Motel.rotated_angle(-1,  0,  0,  1,  0,  0,  0,  0, -1).should be_within(CLOSE_ENOUGH).of(  Math::PI)
  
      Motel.rotated_angle( 1,  0,  0,  1,  0,  0, -1,  0,  0).should == 0
      Motel.rotated_angle(-1,  0,  0, -1,  0,  0,  1,  0,  0).should == 0
  
      nvec = [0.46278694184401675, -0.07065487120587671, 0.5962620387635114]
      ovec = [0.17853313988175556, 0.2454032447769472, 0.6946909015193612] 
      axis = [0.7246334184522361, 0.5503970568277818, 0.3253349322942892]
      expected = 0.7956383064938639
      Motel.rotated_angle(*nvec, *ovec, *axis).should == expected
  
      nvec = [0.6380341734080698,0.4583728273961532,-0.618713782510409]
      ovec = [0.4915391523114243,0.5734623443633283,-0.6553855364152325]
      axis = [-0.6359987280038161,-0.741998516004452,0.211999576001272]
      expected = 0.3978834242226452
      Motel.rotated_angle(*nvec, *ovec, *axis).should == expected
  
      nvec = [-0.6906942457724452,0.7205253611830508,-0.06151961271714489]
      ovec = [-0.813733471206735,0.5812381937190965,0.0]
      axis = [-0.4472135954999579,0.0,-0.8944271909999159]
      expected = 0.21056572302717502
      Motel.rotated_angle(*nvec, *ovec, *axis).should == expected
    end
  
    it "should return angle used to generate rotation" do
      r = rand
      ovec = Motel.rand_vector
      axis = Motel.rand_vector
      nvec = Motel.rotate(*ovec, r, *axis)
      result = Motel.rotated_angle(*nvec, *ovec, *axis)
      result.should be_within(CLOSE_ENOUGH).of(r)
    end
  
    context "invalid params" do
      it "raises ArgumentError" do
        lambda{
          Motel.rotated_angle( 1,  0,  0,  0,  1,  0,  0,  0,  0)
        }.should raise_error(ArgumentError)
  
        lambda{
          Motel.rotated_angle( 0,  0,  0,  0,  1,  0,  1,  0,  0)
        }.should raise_error(ArgumentError)
  
        lambda{
          Motel.rotated_angle( 1,  0,  0,  0,  0,  0,  0,  1,  0)
        }.should raise_error(ArgumentError)
  
        lambda{
          Motel.rotated_angle( 1,  0,  0,  0,  0,  2,  0,  1,  0)
        }.should raise_error(ArgumentError)
  
        lambda{
          Motel.rotated_angle( 1,  0,  0,  0,  0.5,  0.5,  0,  1,  0)
        }.should raise_error(ArgumentError)
      end
    end
  end
  
  describe "#elliptical_path" do
    it "returns coordinates in an elliptical path of the specified e/p/direction"
  end
  
  describe "#orthogonal?" do
    context "vectors are orthogonal" do
      it "returns true" do
        Motel.orthogonal?(1,0,0, 0,1,0).should be_true
        Motel.orthogonal?(1,0,0, 0,0,1).should be_true
        Motel.orthogonal?(0,1,0, 0,0,1).should be_true
  
        Motel.orthogonal?(-1,0,0, 0,-1,0).should be_true
        Motel.orthogonal?(1,0,0, 0,0,-1).should  be_true
        Motel.orthogonal?(0,-1,0, 0,0,1).should  be_true
  
        Motel.orthogonal?(1,3,2, 3,-1,0).should  be_true
      end
    end
  
    context "vectors are not orthogonal" do
      it "returns false" do
        Motel.orthogonal?(1,0,0, -1,0,0).should be_false
        Motel.orthogonal?(1,0,0, 1,0,0).should  be_false
        Motel.orthogonal?(0.5,0.14,0.98, 7.1,-6.5,0).should  be_false
      end
    end
  end
end
