# common module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe "gen_uuid" do

  it "should generate valid uuid" do
    uuid = Motel.gen_uuid 
    uuid.size.should == 36
    uuid.should =~ /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/
  end

end

describe "normalize" do

  it "shoud not affect a normalized vector" do
    x,y,z = Motel.normalize 1,0,0
    x.should == 1
    y.should == 0
    z.should == 0

    x,y,z = Motel.normalize 0,1,0
    x.should == 0
    y.should == 1
    z.should == 0

    x,y,z = Motel.normalize 0,0,1
    x.should == 0
    y.should == 0
    z.should == 1
  end

  it "should raise an error if an invalid vector is passed in" do
    lambda{
      Motel.normalize 0,0,0
    }.should raise_error(ArgumentError)
  end

  it "should correctly normalize vector" do
    x,y,z = Motel.normalize 0.5,0.5,0.5
    (x - 0.577350269189626).should < CLOSE_ENOUGH
    (y - 0.577350269189626).should < CLOSE_ENOUGH
    (z - 0.577350269189626).should < CLOSE_ENOUGH

    x,y,z = Motel.normalize 0.75,0.6,0.12
    (x - 0.77484465921718).should   < CLOSE_ENOUGH
    (y - 0.619875727373744).should  < CLOSE_ENOUGH
    (z - 0.123975145474749).should  < CLOSE_ENOUGH
  end

end

describe "normalized?" do
 it "should return true for normalized vectors" do
    Motel.normalized?(0, 0, 1).should be_true
 end

 it "should return false for non-normalized vectors" do
    Motel.normalized?(1, 1, 1).should be_false
    Motel.normalized?(0, 0, 0).should be_false
    Motel.normalized?(0.5, 0.5, 0.5).should be_false
 end
end

describe "random_axis" do
  it "should generate three dimensional random axis by default" do
    axis_vector1, axis_vector2 = Motel.random_axis
    axis_vector1.size.should == 3
    axis_vector2.size.should == 3

    axis_vector1.find { |c| c == 0 }.should be_nil
    axis_vector2.find { |c| c == 0 }.should be_nil

    nav1 = Motel.normalize(*axis_vector1)
    nav2 = Motel.normalize(*axis_vector2)

    0.upto(2) { |i|
      (axis_vector1[i] - nav1[i]).should < CLOSE_ENOUGH
      (axis_vector2[i] - nav2[i]).should < CLOSE_ENOUGH
    }

    Motel.orthogonal?(*(axis_vector1 + axis_vector2)).should be_true
  end

  it "should allow invoker to generate a two dimensional random axis" do
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

  it "should raise error if an invalid number of dimensions were specified" do
    lambda{
      Motel.random_axis :dimensions => 2
      Motel.random_axis :dimensions => 3
    }.should_not raise_error

    lambda{
      Motel.random_axis :dimensions => 5
    }.should raise_error(ArgumentError)
  end
end

describe "orthogonal?" do
 it "should return true for orthoginal vectors" do
    Motel.orthogonal?(1,0,0, 0,1,0).should == true
    Motel.orthogonal?(1,0,0, 0,0,1).should == true
    Motel.orthogonal?(0,1,0, 0,0,1).should == true

    Motel.orthogonal?(-1,0,0, 0,-1,0).should == true
    Motel.orthogonal?(1,0,0, 0,0,-1).should  == true
    Motel.orthogonal?(0,-1,0, 0,0,1).should  == true

    Motel.orthogonal?(1,3,2, 3,-1,0).should  == true
 end

 it "should return false for nonorthoginal vectors" do
    Motel.orthogonal?(1,0,0, -1,0,0).should == false
    Motel.orthogonal?(1,0,0, 1,0,0).should  == false
    Motel.orthogonal?(0.5,0.14,0.98, 7.1,-6.5,0).should  == false
 end
end

describe Float do
  it "should correctly round to specified percision" do
      5.12345.round_to(1).should == 5.1
      -5.12345.round_to(2).should == -5.12
      5.12345.round_to(6).should == 5.12345
  end
end
