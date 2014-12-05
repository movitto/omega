# Location Generators Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  describe "#basic" do
    it "returns new minimal location" do
      l = Location.basic(123)
      l.should be_an_instance_of(Location)
      l.should be_valid

      l.id.should == 123
      l.parent.should == nil
      l.parent_id.should == nil
      l.movement_strategy.should == MovementStrategies::Stopped.instance
      l.coordinates.should == [0,0,0]
      l.orientation.should == [0,0,1]
    end
  end

  describe "#random" do
    it "returns new random location" do
      r = Motel::Location.random
      r.should be_an_instance_of(Location)

      # should just be missing an id
      r.should_not be_valid
      r.id = 42
      r.should be_valid
    end

    context "maximum specified" do
      it "constrains coordinates to maximums" do
        l = Location.random :max_x => 10
        l.x.should be <   10
        l.x.should be >= -10

        l = Location.random :max => 10
        l.x.should be <   10
        l.x.should be >= -10
        l.y.should be <   10
        l.y.should be >= -10
        l.z.should be <   10
        l.z.should be >= -10
      end
    end

    context "minimum specified" do
      it "constrains coordinates to minimums" do
        l = Location.random :min_x => 10
        l.x.abs.should be >=  10

        l = Location.random :min => 10
        l.x.abs.should be >=  10
        l.y.abs.should be >=  10
        l.z.abs.should be >=  10
      end
    end
  end
end # describe Location
end # module Motel
