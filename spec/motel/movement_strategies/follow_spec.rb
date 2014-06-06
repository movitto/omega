# follow movement strategy tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/follow'

module Motel::MovementStrategies
describe Follow do
  describe "#tracked_location=" do
    it "sets tracked location" do
      l = build(:location)
      f = Follow.new
      f.tracked_location = l
      f.tracked_location.should == l
    end

    it "sets tracked location id" do
      l = build(:location)
      f = Follow.new
      f.tracked_location = l
      f.tracked_location_id.should == l.id
    end
  end

  describe "#initialize" do
    it "sets attributes" do
      follow = Follow.new :tracked_location_id => 'loc1',
                          :distance => 20, :speed => 5
      follow.tracked_location_id.should == 'loc1'
      follow.distance.should == 20
      follow.speed.should == 5
    end
  end

  describe "#valid?" do
    context "tracked location is nil" do
      it "returns false" do
        follow = Follow.new :speed => 10, :distance => 10
        follow.should_not be_valid
      end
    end

    context "speed is invalid" do
      it "returns false" do
        f = Follow.new :tracked_location_id => 42, :distance => 10
        f.should_not be_valid

        f = Follow.new :tracked_location_id => 42, :distance => 10,
                       :speed => "32"
        f.should_not be_valid

        f = Follow.new :tracked_location_id => 42, :distance => 10,
                       :speed => -10
        f.should_not be_valid

        f = Follow.new :tracked_location_id => 42, :distance => 10,
                       :speed => 0
        f.should_not be_valid
      end
    end

    context "distance is invalid" do
      it "returns false" do
        f = Follow.new :tracked_location_id => 42, :speed => 10
        f.should_not be_valid

        f = Follow.new :tracked_location_id => 42, :speed => 10,
                       :distance => "32"
        f.should_not be_valid

        f = Follow.new :tracked_location_id => 42, :speed => 10,
                       :distance => 0
        f.should_not be_valid

        f = Follow.new :tracked_location_id => 42, :speed => 10,
                       :distance => -10
        f.should_not be_valid
      end
    end

    context "follow is valid" do
      it "returns true" do
        f = Follow.new :tracked_location_id => 42,
                       :speed => 10,
                       :distance => 10
        f.should be_valid
      end
    end
  end

  describe "#move" do
    before(:each) do
      @o = build(:location)
      @l = build(:location)
      @l.parent = @p
    end

    context "follow is not valid" do
      it "does not move location" do
        follow = Follow.new :tracked_location_id => nil,
                            :distance => 10, :speed => 5
        lambda {
          follow.move @l, 1
        }.should_not change(@l, :coordinates)
      end
    end

    context "tracked location is nil" do
      it "does not move location" do
        follow = Follow.new :tracked_location_id => 42,
                            :distance => 10, :speed => 5
        lambda {
          follow.move @l, 1
        }.should_not change(@l, :coordinates)
      end
    end

    context "tracked location has different parent" do
      it "does not move location" do
        p2 = build(:location)
        l2 = build(:location)
        l2.parent = p2

        follow = Follow.new :tracked_location_id => l2.id,
                            :distance => 10, :speed => 5
        follow.tracked_location = l2

        lambda {
          follow.move @l, 1
        }.should_not change(@l, :coordinates)
      end
    end

    context "tracked location is <= distance away" do
      it "does not move location" do
        l2 = build(:location)
        l2.parent = @p
        l2.x,l2.y,l2.z = *@l.coordinates
        l2.x -= 5

        follow = Follow.new :tracked_location_id => l2.id,
                            :distance => 10, :speed => 5

        lambda {
          follow.move @l, 1
        }.should_not change(@l, :coordinates)
      end
    end

    it "moves location in direction towards target by speed * elapsed time" do
      p   = Motel::Location.new
      l1 = Motel::Location.new(:id => 1, :parent => p,
                               :x => 20, :y => 0, :z => 0,
                               :orientation_x => -1,
                               :orientation_y =>  0,
                               :orientation_z =>  0)
      l2 = Motel::Location.new(:id => 2, :parent => p,
                               :x => 0,  :y => 0, :z => 0,
                               :orientation_x => 1,
                               :orientation_y => 0,
                               :orientation_z => 0)

      follow = Follow.new :tracked_location_id => l2.id,
                          :distance => 10, :speed => 5
      follow.tracked_location = l2

      # move and validate
      follow.move l1, 1
      l1.x.should == 15

      follow.move l1, 1
      l1.x.should == 10

      follow.move l1, 1
      l1.x.should == 10
    end
  end

  describe "#to_json" do
    it "returns follow in json format" do
      m = Follow.new :step_delay => 20,
                     :speed      => 15,
                     :tracked_location_id =>  1,
                     :distance =>  22

      j = m.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Follow"')
      j.should include('"step_delay":20')
      j.should include('"speed":15')
      j.should include('"tracked_location_id":1')
      j.should include('"distance":22')
    end
  end

  describe "#json_create" do
    it "returns follow from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Follow","data":{"speed":15,"tracked_location_id":1,"distance":22,"step_delay":20}}'
      m = RJR::JSONParser.parse(j)

      m.class.should == Motel::MovementStrategies::Follow
      m.step_delay.should == 20
      m.speed.should == 15
      m.tracked_location_id.should == 1
      m.distance.should == 22
    end
  end

end # describe Follow
end # module Motel::MovementStategies
