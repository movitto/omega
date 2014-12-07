# Location HasCoordinates Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  let(:loc)   { build(:location) }
  let(:other) { build(:location) }

  describe "#coordinates_from_args" do
    it "initializes coordinates from compact args" do
      loc.coordinates_from_args :coordinates => [10, 1, 0]
      loc.x.should == 10
      loc.y.should == 1
      loc.z.should == 0

      loc.coordinates_from_args 'coordinates' => [2000, 0, -1]
      loc.x.should == 2000
      loc.y.should == 0
      loc.z.should == -1
    end

    it "initializes coordinates" do
      loc.coordinates_from_args :x => 75, :y => 50, :z => -1
      loc.x.should == 75
      loc.y.should == 50
      loc.z.should == -1
    end

    it "converts coordinates to floats" do
      loc.coordinates_from_args :x => '75.0', :y => '19.1', :z => '-14.9'
      loc.x.should ==  75.0
      loc.y.should ==  19.1
      loc.z.should == -14.9
    end
  end

  describe "#coordinates_valid?" do
    context "all coordinates are numeric" do
      it "returns true" do
        loc.coordinates_valid?.should be_true
      end
    end

    context "at least one coordinate is not numeric" do
      it "returns false" do
        loc.x = 'a'
        loc.coordinates_valid?.should be_false

        loc.x = 1
        loc.y = 'b'
        loc.coordinates_valid?.should be_false

        loc.y = 2
        loc.z = 'c'
        loc.coordinates_valid?.should be_false
      end
    end
  end

  describe "#coordinates" do
    it "returns array of coordinates" do
      loc.x = 1
      loc.y = 2
      loc.z = 3
      loc.coordinates.should == [1,2,3]
    end
  end

  describe "#coordinates=" do
    it "sets location's coordinates" do
      loc.coordinates = 1, 2, 3
      loc.x.should == 1
      loc.y.should == 2
      loc.z.should == 3

      loc.coordinates = [4, 5, 6]
      loc.x.should == 4
      loc.y.should == 5
      loc.z.should == 6
    end
  end

  [:total_x, :total_y, :total_z].each { |t|
    describe "##{t}" do
      before(:each) do
        @c = t.to_s.gsub(/total_/, '').intern
      end

      context "parent is nil" do
        it "returns 0" do
          loc.parent = nil
          loc.send(t).should == 0
        end
      end

      context "parent is not nil" do
        it "calls parent #{t}" do
          p = Location.new @c => 0
          l = Location.new @c => 0
          l.parent = p
          p.should_receive(t).and_call_original
          l.send(t)
        end

        it "returns parent.#{t} + [x|y|z]" do
          g = Location.new
          p = Location.new  @c => -20
          l = Location.new  @c =>  10
          p.parent = g ; l.parent = p
          p.send(t).should == -20
          l.send(t).should == -10
        end
      end
    end
  }

  describe "#-" do
    it "return distance between locations" do
      l1 = Location.new :x => 10, :y => 10, :z => 10
      l2 = Location.new :x => -5, :y => -7, :z => 30
      (l1 - l2).should be_within(OmegaTest::CLOSE_ENOUGH).of(30.2324329156619)
    end
  end

  describe "#distance_from" do
    it "returns distance between coordinates and specified point" do
      loc.x = 10
      loc.y = 20
      loc.z = 30
      loc.distance_from(-20, 60, 150).should == 130
    end
  end

  describe "#distance_from_origin" do
    it "returns distance from coordinates to origin" do
      loc.x    = -99
      loc.y    = 1032
      loc.z    = 386324
      expected = 386325.3910902052
      loc.distance_from_origin.should == expected
    end
  end

  describe "#direction_to" do
    it "returns direction from coordinates to specified point" do
      loc.x = 10
      loc.y = 20
      loc.z = 30
      expected = [0.23076923076923078, -0.3076923076923077, -0.9230769230769231]
      loc.direction_to(-20, 60, 150).should == expected
    end
  end

  describe "#+" do
    it "returns new location" do
      l1 = Location.new :coordinates => [0, 0, 0]
      l2 = l1 + [10, 10, 10]
      l2.should be_an_instance_of(Location)
      l2.should_not equal(l1)
    end

    it "updates new location from self" do
      l1 = Location.new :parent_id => 50, :coordinates => [0, 0, 0],
                        :movement_strategy => MovementStrategies::Linear.new
      l2 = l1 + [10,10,10]
      l2.parent_id.should == 50
      l2.movement_strategy.should be_an_instance_of(MovementStrategies::Linear)
    end

    it "adds specified values to coordinates" do
      l1 = Motel::Location.new :x => 4, :y => 2, :z => 0
      l2 = l1 + [10, 20, 30]

      l1.x.should == 4
      l1.y.should == 2
      l1.z.should == 0
      l2.x.should == 14
      l2.y.should == 22
      l2.z.should == 30
    end
  end

  describe "#coordinates_json" do
    it "returns coordinates json data hash" do
      loc.coordinates_json.should be_an_instance_of(Hash)
    end

    it "returns coordinates in json data hash" do
      loc.x = 42
      loc.y = -100
      loc.z = 2000
      loc.coordinates_json[:x].should == 42
      loc.coordinates_json[:y].should == -100
      loc.coordinates_json[:z].should == 2000
    end
  end

  describe "#coordinates_eql?" do
    context "at least one coordinate does not equal other" do
      it "returns false" do
        loc.coordinates   = 100, 200, -10
        other.coordinates =  90, 200, -10
        loc.coordinates_eql?(other).should be_false
      end
    end

    it "returns true" do
        loc.coordinates   = 90, 200, -10
        other.coordinates = 90, 200, -10
        loc.coordinates_eql?(other).should be_true
    end
  end
end # describe Location
end # module Motel
