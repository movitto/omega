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
  it "return cross product between vectors"
end

describe "#dot_product" do
  it "returns dot product of vectors"
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

describe "#spherical" do
  it "returns spherical coordinates" do
    spherical = Motel.to_spherical(0, 0, 0)
    spherical.size.should == 3
    spherical[0].round_to(2).should == 0
    spherical[1].round_to(2).should == 0
    spherical[2].round_to(2).should == 0

    spherical = Motel.to_spherical(1, 0, 0)
    spherical.size.should == 3
    spherical[0].round_to(2).should == 1.57
    spherical[1].round_to(2).should == 0
    spherical[2].round_to(2).should == 1

    spherical = Motel.to_spherical(0, 2, 0)
    spherical.size.should == 3
    spherical[0].round_to(2).should == 1.57
    spherical[1].round_to(2).should == 1.57
    spherical[2].round_to(2).should == 2

    spherical = Motel.to_spherical(0, 0, 1)
    spherical.size.should == 3
    spherical[0].round_to(2).should == 0
    spherical[1].round_to(2).should == 0
    spherical[2].round_to(2).should == 1

    # TODO test more coords
  end
end

describe "#from_spherical" do
  it "returns catersian coordinates" do
    cartesian = Motel.from_spherical(0, 0, 0)
    cartesian.size.should == 3
    cartesian[0].round_to(2).should == 0
    cartesian[1].round_to(2).should == 0
    cartesian[2].round_to(2).should == 0

    cartesian = Motel.from_spherical(-1.57, 0, 1)
    cartesian.size.should == 3
    cartesian[0].round_to(2).should == -1
    cartesian[1].round_to(2).should == 0
    cartesian[2].round_to(2).should == 0

    cartesian = Motel.from_spherical(0, -2.356, 2)
    cartesian.size.should == 3
    cartesian[0].round_to(2).should == 0
    cartesian[1].round_to(2).should == 0
    cartesian[2].round_to(2).should == 2

    # TODO test more coords
  end

describe "#to_spherical/#from_spherical" do
  it "is symmetrical" do
    o = [9, -8, 5]
    n = Motel.from_spherical(*Motel.to_spherical(*o))
    #n.should == o
    0.upto(2) { |i| (o[i] - n[i]).abs.should < 0.1 }

    o = [0.45, 2.33, 2]
    n = Motel.to_spherical(*Motel.from_spherical(*o))
    #n.should == o
    0.upto(2) { |i| (o[i] - n[i]).abs.should < 0.1 }

    ain = [3.2815926535897932, 0.7031853071795819, 1]
    Motel.to_spherical(*Motel.from_spherical(*ain)).should == ain

    bin = [-0.1064415732380847, -0.09023564889341674, -0.9902159962126371]
    Motel.from_spherical(*Motel.to_spherical(*bin)).should == bin
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

  context "dimension < 2 or > 3"
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
