# Location HasCoordinates Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  describe "#coordinates" do
    it "returns array of coordinates" do
      l = Location.new :x => 1, :y => 2, :z => 3
      l.coordinates.should == [1,2,3]
    end
  end

  describe "#coordinates=" do
    it "sets location's coordinates" do
      l = Location.new
      l.coordinates = 1, 2, 3
      l.x.should == 1
      l.y.should == 2
      l.z.should == 3

      l.coordinates = [4, 5, 6]
      l.x.should == 4
      l.y.should == 5
      l.z.should == 6
    end
  end

  [:total_x, :total_y, :total_z].each { |t|
    describe "##{t}" do
      before(:each) do
        @c = t.to_s.gsub(/total_/, '').intern
      end

      context "parent is nil" do
        it "returns 0" do
          l = Location.new
          l.parent = nil
          l.send(t).should == 0
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

  describe "#distance_from" do
    it "returns distance between coordinates and specified point" do
      l = Motel::Location.new :x => 10, :y => 20, :z => 30
      l.distance_from(-20, 60, 150).should == 130
    end
  end

  describe "#direction_to" do
    it "returns direction from coordinates to specified point" do
      l = Motel::Location.new :x => 10, :y => 20, :z => 30
      dir = l.direction_to(-20, 60, 150)
      dir.should == [0.23076923076923078, -0.3076923076923077, -0.9230769230769231]
    end
  end
end # describe Location
end # module Motel
