# common module tests
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Motel
describe "#gen_uuid" do
  it "returns a random uuid" do
    uuid = Motel.gen_uuid 
    uuid.should be_an_instance_of(String)
    uuid.size.should == 36
    uuid.should =~ /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/
    Motel.gen_uuid.should_not == uuid
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
  it "returns the angle between vectors"
end

describe "#axis_angle" do
  it "returns the axis angle between two vectors"
end

describe "#rotate" do
  it "returns coordinate rotated around axis angle"
end

describe "#rotated_angle" do
  it "returns the angle component of the axis-angle specified by axis and new/old coordinates"
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

describe "#rand_vector" do
  it "returns a random vector" do
    v1 = Motel.rand_vector
    v2 = Motel.rand_vector
    v1.size.should == 3
    v2.size.should == 3
    Motel.normalized?(*v1).should be_true
    Motel.normalized?(*v2).should be_true
    v1.should_not == v2
  end
end

describe "#random_axis" do
  it "returns a random 3d axis" do
    axis_vector1, axis_vector2 = Motel.random_axis
    axis_vector1.size.should == 3
    axis_vector2.size.should == 3

    axis_vector1.find { |c| c == 0 }.should be_nil
    axis_vector2.find { |c| c == 0 }.should be_nil

    nav1 = Motel.normalize(*axis_vector1)
    nav2 = Motel.normalize(*axis_vector2)

    0.upto(2) { |i|
      axis_vector1[i].should be_within(OmegaTest::CLOSE_ENOUGH).of(nav1[i])
      axis_vector2[i].should be_within(OmegaTest::CLOSE_ENOUGH).of(nav2[i])
    }

    Motel.orthogonal?(*(axis_vector1 + axis_vector2)).should be_true
  end

  it "returns a random 2d axis" do
    axis_vector1, axis_vector2 = Motel.random_axis :dimensions => 2
    axis_vector1.size.should == 3
    axis_vector2.size.should == 3

    axis_vector1[0].should_not == 0
    axis_vector1[1].should_not == 0
    axis_vector1[2].should == 0
    axis_vector2[0].should_not == 0
    axis_vector2[1].should_not == 0
    axis_vector2[2].should == 0
  end

  context "dimension < 2 or > 3" do
    it "raises an ArgumentError" do
      lambda{
        Motel.random_axis :dimensions => 2
        Motel.random_axis :dimensions => 3
      }.should_not raise_error

      lambda{
        Motel.random_axis :dimensions => 5
      }.should raise_error(ArgumentError)
    end
  end
end
end # module Motel

describe Float do
  it "should correctly round to specified percision" do
      5.12345.round_to(1).should == 5.1
      -5.12345.round_to(2).should == -5.12
      5.12345.round_to(6).should == 5.12345
  end
end
