# Motel Generators Spec
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Motel
  describe "#gen_uuid" do
    it "returns a random uuid" do
      uuid = Motel.gen_uuid
      uuid.should be_an_instance_of(String)
      uuid.size.should == 36
      uuid.should =~ UUID_PATTERN
      Motel.gen_uuid.should_not == uuid
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
  
    context "orthogonal_to vector is specified" do
      it "generates a random axis orthogonal to the specified vector" do
        v = Motel.rand_vector
        axis_vector1, axis_vector2 = Motel.random_axis  :orthogonal_to => v
        Motel.dot_product(*axis_vector1, *v).should be_within(OmegaTest::CLOSE_ENOUGH).of(0)
        Motel.dot_product(*axis_vector2, *v).should be_within(OmegaTest::CLOSE_ENOUGH).of(0)
      end
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
end
