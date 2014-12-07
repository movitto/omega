# Location Trackable Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  let(:loc)   { build(:location) }
  let(:other) { build(:location) }

  describe "#trackable_state_from_args" do
    it "initializes distance moved" do
      loc.trackable_state_from_args :distance_moved => 50
      loc.distance_moved.should == 50
    end

    it "initializes angle_rotated" do
      loc.trackable_state_from_args :angle_rotated => 0.1
      loc.angle_rotated.should == 0.1
    end

    it "initializes last_moved_at" do
      t = Time.now
      loc.trackable_state_from_args :last_moved_at => t
      loc.last_moved_at.should == t
    end

    it "defaults last_moved_at to nil" do
      loc.trackable_state_from_args({}) 
      loc.last_moved_at.should be_nil
    end

    it "converts string last moved at to time" do
      t = Time.now
      loc.trackable_state_from_args :last_moved_at => t.to_s
      loc.last_moved_at.should be_within(1).of(t)
    end
  end

  describe "#reset_tracked_attributes" do
    it "should reset distance moved" do
      l = Location.new
      l.distance_moved = 50
      l.reset_tracked_attributes
      l.distance_moved.should == 0
    end

    it "should reset angle rotated" do
      l = Location.new
      l.angle_rotated = 3.14
      l.reset_tracked_attributes
      l.angle_rotated.should == 0
    end
  end

  describe "#trackable_json" do
    it "returns trackable json data hash" do
      loc.trackable_json.should be_an_instance_of(Hash)
    end

    it "returns distance_moved in trackable_json data hash" do
      loc.distance_moved = 50
      loc.trackable_json[:distance_moved].should == 50
    end

    it "returns angle_rotated in trackable json data hash" do
      loc.angle_rotated = 0.2
      loc.trackable_json[:angle_rotated].should == 0.2
    end

    it "returns last_moved_at in trackable json data hash" do
      t = Time.now
      loc.last_moved_at = t
      loc.trackable_json[:last_moved_at].should == loc.last_moved_str
    end
  end

  describe "#last_moved_str" do
    it "returns last_moved_at in string format" do
      t = Time.now
      f = "%d %b %Y %H:%M:%S.%5N"
      expected = t.strftime(f)

      loc.last_moved_at = t
      loc.last_moved_str.should == expected
    end
  end

  describe "#time_since_movement" do
    context "last_moved_at is nil" do
      it "returns nil" do
        loc.last_moved_at = nil
        loc.time_since_movement.should be_nil
      end
    end

    it "returns Time.now - last_moved_at" do
      t = Time.now - 10
      loc.last_moved_at = t
      loc.time_since_movement.should be_within(CLOSE_ENOUGH*10).of(10)
    end
  end

  describe "#trackable_state_eql?" do
    before(:each) do
      loc.distance_moved = other.distance_moved = 50
      loc.angle_rotated  = other.angle_rotated  = 0.2
      loc.last_moved_at  = other.last_moved_at  = Time.now
    end

    context "distance_moved != other.distance_moved" do
      it "returns false" do
        loc.distance_moved += 1
        loc.trackable_state_eql?(other).should be_false
      end
    end

    context "angle_rotated != other.angle_rotated" do
      it "returns false" do
        loc.angle_rotated += 1
        loc.trackable_state_eql?(other).should be_false
      end
    end

    context "last_moved_at != other.last_moved_at" do
      it "returns false" do
        loc.last_moved_at = Time.now
        loc.trackable_state_eql?(other).should be_false
      end
    end

    it "returns true" do
      loc.trackable_state_eql?(other).should be_true
    end
  end
end # describe Location
end # module Motel
