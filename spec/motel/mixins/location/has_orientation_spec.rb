# Location HasOrientation Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  let(:loc)   { build(:location) }
  let(:other) { build(:location) }

  describe "#orientation_from_args" do
    it "initializes orientation from combined arg" do
      loc.orientation_from_args :orientation => [0, 1, 0]
      loc.orientation_x.should == 0
      loc.orientation_y.should == 1
      loc.orientation_z.should == 0

      loc.orientation_from_args 'orientation' => [1, 0, 0]
      loc.orx.should == 1
      loc.ory.should == 0
      loc.orz.should == 0
    end

    it "initializes orientation from individual args" do
      loc.orientation_from_args :orientation_x => 0,
                                :orientation_y => 0,
                                :orientation_z => 1
      loc.orientation.should == [0, 0, 1]
    end

    it "initializes orientation from shorthand args" do
      loc.orientation_from_args :orx => 0,
                                :ory => 0,
                                :orz => 1
      loc.orientation.should == [0, 0, 1]
    end

    it "converts orientation to float" do
      loc.orientation_from_args :orx => '1',
                                :ory => '0',
                                :orz => '0'
      loc.orientation.should == [1, 0, 0]
    end
  end

  describe "#orientation_valid?" do
    context "all orientation values are numeric" do
      it "returns true" do
        loc.orientation = 0, 1, 0
        loc.orientation_valid?.should be_true
      end
    end

    context "at least one orientation value is not numeric" do
      it "returns false" do
        loc.orx = loc.ory = loc.orz = 0

        loc.orx = '0'
        loc.orientation_valid?.should be_false

        loc.orx =  0
        loc.ory = '0'
        loc.orientation_valid?.should be_false

        loc.ory =  0
        loc.orz = '0'
        loc.orientation_valid?.should be_false
      end
    end
  end

  describe "#orientation" do
    it "returns array of orientation" do
      l = Location.new :orientation_x => 1,
                       :orientation_y => 2,
                       :orientation_z => 3
      l.orientation.should == [1,2,3]
    end
  end

  describe "#orientation=" do
    it "sets location's orientation" do
      l = Location.new
      l.orientation = 1, 2, 3
      l.orientation.should == [1,2,3]
      l.orientation = [4,5,6]
      l.orientation.should == [4,5,6]
    end
  end

  describe "#orientation_difference" do
    it "returns spherical orientation difference" do
      l = Location.new :coordinates => [0, 0, 0],
                       :orientation => [0, 0, 1]
      l.orientation_difference(0, 0, 1).should  == [0, 0, 1, 0]
      l.orientation_difference(0, 0, 2).should  == [0, 0, 1, 0]

      l.orientation_difference(0, 0, -1).should == [Math::PI, 0, 1, 0]
      l.orientation_difference(1, 0, 0).should  == [Math::PI/2, 0, 1, 0]
      l.orientation_difference(-1, 0, 0).should == [Math::PI/2, 0, -1, 0]
      l.orientation_difference(0, 1, 0).should  == [Math::PI/2, -1, 0, 0]
      l.orientation_difference(1, 1, 0).should  == [Math::PI/2, -0.7071067811865475, 0.7071067811865475, 0.0]
    end

    context "tried to specify orientation towards location's own coordinate" do
      it "raises ArgumentError" do
        l = Location.new :coordinates => [0, 0, 0],
                         :orientation => [0.57, 0.57, 0.57]
        lambda{
          l.orientation_difference(0, 0, 0)
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#rotation_to" do
    it "returns orientation difference to specified trajectory" do
      l = Motel::Location.new :x => 10, :y => 20, :z => 30,
                              :orientation => [0, 0, 1]
      l.rotation_to(-20, 60, 150).should == [0.3947911196997614, -0.8, -0.6, 0.0]
    end
  end

  describe "#facing?" do
    context "location oriented towards coordinate" do
      it "returns true" do
        l = Location.new :coordinates => [0, 0, 0],
                         :orientation => [0.57, 0.57, 0.57]
        l.facing?(0.57, 0.57, 0.57).should be_true
        l.facing?(1.14, 1.14, 1.14).should be_true
        l.facing?(0.285, 0.285, 0.285).should be_true
      end
    end

    context "location not orientated towards coordinate" do
      it "returns false" do
        l = Location.new :coordinates => [0, 0, 0],
                         :orientation => [0.57, 0.57, 0.57]

        l.facing?(1, 0, 0).should be_false
        l.facing?(-100, 50, 100).should be_false
      end
    end
  end

  describe "#facing?" do
    context "rotation_to angle is greater than default tolerance" do
      it "returns false" do
        l = Motel::Location.new :x => 10, :y => 20, :z => 30,
                                :orientation => [0, 0, 1]
        l.facing?(-20, 60, 150).should be_false
      end
    end

    context "rotation_to angle is greater than specified tolerance" do
      it "returns false" do
        l = Motel::Location.new :x => 20, :y => 60, :z => 190,
                                :orientation => [0, 0, 1]
        l.facing?(-20, 60, 150, :tolerance => Math::PI/2).should be_false
      end
    end

    context "rotation_to angle is less than default tolerance" do
      it "returns true" do
        l = Motel::Location.new :x => -20, :y => 60, :z => 30,
                                :orientation => [0, 0, 1]
        l.facing?(-20, 60, 150).should be_true
      end
    end

    context "rotation_to angle is less than specified tolerance" do
      it "returns true" do
        l = Motel::Location.new :x => -20, :y => 70, :z => 30,
                                :orientation => [0, 0, 1]
        l.facing?(-20, 60, 150, :tolerance => Math::PI/4).should be_true
      end
    end
  end

  describe "#orientation_json" do
    it "returns orientation json data hash" do
      loc.orientation_json.should be_an_instance_of(Hash)
    end

    it "return orientation in json data hash" do
      loc.orientation = [1, 0, 0]
      loc.orientation_json[:orientation_x].should == 1
      loc.orientation_json[:orientation_y].should == 0
      loc.orientation_json[:orientation_z].should == 0
    end
  end

  describe "#orientation_str" do
    it "returns orientation in string format" do
      loc.orientation = 0.9370425713316364, -0.15617376188860607, 0.31234752377721214
      loc.orientation_str.should == "0.94,-0.16,0.31"
    end
  end

  describe "#orienation_eql?" do
    context "orientation values == other orientation values" do
      it "returns true" do
        loc.orientation = other.orientation = [0,1,0]
        loc.orientation_eql?(other).should be_true
      end
    end

    context "orientation values != other orientation values" do
      it "returns true" do
        loc.orientation   = 1,0,0
        other.orientation = 0,1,0
        loc.orientation_eql?(other).should be_false
      end
    end
  end
end # describe Location
end # module Motel
