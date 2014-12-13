# TracksLocations Strategy Mixin Specs
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Motel
module MovementStrategies
describe TracksLocation do
  let(:ms)  { Object.new.extend(TracksLocation) }
  let(:loc) { build(:location) }
  let(:tracked_loc) { build(:location) }

  describe "#has_tracked_location?" do
    context "tracked location is nil" do
      it "returns false" do
        ms.has_tracked_location?.should be_false
      end
    end

    context "tracked location is not nil" do
      it "returns true" do
        ms.tracked_location = loc
        ms.has_tracked_location?.should be_true
      end
    end
  end

  describe "#tracked_location=" do
    it "sets tracked location" do
      ms.tracked_location = loc
      ms.tracked_location.should == loc
    end

    it "sets tracked location id" do
      ms.tracked_location = loc
      ms.tracked_location_id.should == loc.id
    end
  end

  describe "#trackable_attrs_from_args" do
    it "sets distance" do
      ms.trackable_attrs_from_args :distance => 50
      ms.distance.should == 50
    end

    it "sets tracked location id" do
      ms.trackable_attrs_from_args :tracked_location_id => loc.id
      ms.tracked_location_id.should == loc.id
    end

    it "sets orientation tolerance" do
      ms.trackable_attrs_from_args :orientation_tolerance => Math::PI/64
      ms.orientation_tolerance.should == Math::PI/64
    end

    it "sets defaults"
  end

  describe "#tracked_attrs_valid?" do
    before(:each) do
      ms.tracked_location_id = loc.id
      ms.distance = 50
    end

    context "tracked_location_id is nil" do
      it "returns false" do
        ms.tracked_location_id = nil
        ms.tracked_attrs_valid?.should be_false
      end
    end

    context "distance is not numeric" do
      it "returns false" do
        ms.distance = :a
        ms.tracked_attrs_valid?.should be_false
      end
    end

    context "distance is <= 0" do
      it "returns false" do
        ms.distance = -50
        ms.tracked_attrs_valid?.should be_false
      end
    end

    it "returns true" do
        ms.tracked_attrs_valid?.should be_true
    end
  end

  describe "#trackable_json" do
    it "returns trackable json data hash" do
      ms.trackable_json.should be_an_instance_of(Hash)
    end

    it "returns tracked_location_id in json data hash" do
      ms.tracked_location_id = loc.id
      ms.trackable_json[:tracked_location_id].should == loc.id
    end

    it "returns distance in json data hash" do
      ms.distance = 50
      ms.trackable_json[:distance].should == 50
    end
  end

  describe "#same_system?" do
    context "tracked location parent id is same as location parent id" do
      it "returns true" do
        tracked_loc.parent_id = loc.parent_id
        ms.tracked_location = tracked_loc
        ms.same_system?(loc).should be_true
      end
    end

    context "tracked location parent id is not same as location parent id" do
      it "returns false" do
        ms.tracked_location = tracked_loc
        ms.same_system?(loc).should be_true
      end
    end
  end

  describe "#distance_from" do
    it "returns distance location is from target" do
      ms.distance_from(loc, tracked_loc.coordinates).should == loc - tracked_loc
    end

    it "returns distance location is from tracked_location" do
      ms.tracked_location = tracked_loc
      ms.distance_from(loc).should == loc - tracked_loc
    end
  end

  describe "#near_target?" do
    context "distance from tracked_location < specified distance" do
      it "returns true" do
        ms.tracked_location = tracked_loc
        ms.near_target?(loc, loc - tracked_loc + 1).should be_true
      end
    end

    context "distance from tracked_location > specified distance" do
      it "returns false" do
        ms.tracked_location = tracked_loc
        ms.near_target?(loc, loc - tracked_loc - 1).should be_false
      end
    end

    context "distance from tracked_location < distance" do
      it "returns true" do
        ms.tracked_location = tracked_loc
        ms.distance = loc - tracked_loc + 1
        ms.near_target?(loc).should be_true
      end
    end

    context "distance from tracked_location > distance" do
      it "returns false" do
        ms.tracked_location = tracked_loc
        ms.distance = loc - tracked_loc - 1
        ms.near_target?(loc).should be_false
      end
    end
  end

  describe "#rotation_to_target" do
    it "returns rotation from location to tracked_location" do
      loc.orientation = Motel.rand_vector
      ms.tracked_location = tracked_loc
      ms.rotation_to_target(loc).should == loc.rotation_to(*tracked_loc.coordinates)
    end
  end

  describe "#rotation_to" do
    it "returns rotation from location to specified target" do
      loc.orientation = Motel.rand_vector
      target = Location.random.coordinates
      ms.rotation_to(loc, target).should == loc.rotation_to(*target)
    end
  end

  describe "#facing_target?" do
    context "rotation to tracked_location > orientation tolerance" do
      it "returns false" do
        loc.orientation = 0.0, 0.8320502943378436, -0.554700196225229
        loc.coordinates = 14.026190852223596, 32.244232382080106, -67.61675352830194
        tracked_loc.coordinates = 70.29275574573349, 66.5782822122779, -44.711011521963485
        ms.tracked_location = tracked_loc
        ms.orientation_tolerance = Math::PI/4
        ms.facing_target?(loc).should be_false
      end
    end

    context "rotation to tracked_location <= orientation tolerance" do
      it "returns true" do
        loc.orientation = 1, 0, 0
        loc.coordinates = 0, 0, 0
        tracked_loc.coordinates = 10, 5, 0
        ms.tracked_location = tracked_loc
        ms.orientation_tolerance = Math::PI/4
        ms.facing_target?(loc).should be_true
      end
    end
  end

  describe "#facing_target_tangent?" do
    context "rotation to tracked_location is not within orientation_tolerance of Math::PI/2" do
      it "returns false" do
        loc.orientation = 1, 0, 0
        loc.coordinates = 0, 0, 0
        tracked_loc.coordinates = -1, 5, 0
        ms.tracked_location = tracked_loc
        ms.orientation_tolerance = Math::PI/32
        ms.facing_target_tangent?(loc).should be_false
      end
    end

    context "rotation to tracked_location is within orientation_tolerance of Math::PI/2" do
      it "returns true" do
        loc.orientation = 1, 0, 0
        loc.coordinates = 0, 0, 0
        tracked_loc.coordinates = 1, 5, 0
        ms.tracked_location = tracked_loc
        ms.orientation_tolerance = Math::PI/8
        ms.facing_target_tangent?(loc).should be_true
      end
    end
  end

  describe "#face_target" do
    before(:each) do
      ms.extend(Rotatable)
    end

    it "sets rotation to face tracked_location" do
      rot = [Math::PI/9, 0.1643989873053573, -0.9863939238321437, 0.0]
      ms.should_receive(:rotation_to_target)
        .with(loc)
        .and_return(rot)
      ms.rot_theta = Math::PI

      ms.face_target(loc)
      ms.rot_theta.should == Math::PI
      ms.rot_dir.should == rot[1..3]
      ms.stop_angle.should == rot[0].abs
    end

    it "sets rotation to face specified target" do
      ms.rot_theta = 0.99
      loc.orientation = -0.09205746178983235, 0.8285171561084911, -0.552344770738994
      target = -1.5303931831754602, -4.309751857256938, -19.346149340346763
      rot = loc.rotation_to(*target)

      ms.face_target(loc, target)
      ms.rot_theta.should == 0.99
      ms.rot_dir.should == rot[1..3]
      ms.stop_angle.should == rot[0].abs
    end

    it "resets loc.angle_rotated" do
      loc.angle_rotated = 0.11
      ms.rot_theta = 1.98
      loc.orientation = -0.48507125007266594, -0.48507125007266594, -0.7276068751089989
      target = [88.19773240669853, -96.85693115293903, -38.901357970646146]
      rot = loc.rotation_to(*target)

      ms.face_target(loc, target)
      loc.angle_rotated.should == 0
    end
  end

  describe "#face_away_from_target" do
    before(:each) do
      ms.extend(Rotatable)
    end

    it "sets rotation to face specified angle from tracked_location" do
      loc.orientation = 0.211999576001272, -0.211999576001272, -0.953998092005724
      ms.tracked_location = tracked_loc
      rot = ms.rotation_to_target(loc)
      ms.rot_theta = 1.88

      ms.face_away_from_target loc, rot[0] - 0.1
      ms.rot_theta.should == 1.88
      ms.rot_dir.should == rot[1..3]
      ms.stop_angle.should be_within(CLOSE_ENOUGH).of(0.1)

      ms.face_away_from_target loc, rot[0] + 0.1
      ms.rot_theta.should == 1.88
      ms.rot_dir.should == rot[1..3]
      ms.stop_angle.should == be_within(CLOSE_ENOUGH).of(2*rot[0] + 0.1)
    end

    it "resets loc.angle_rotated" do
      loc.angle_rotated = 0.1
      loc.orientation = -0.4016096644512494, 0.5622535302317492, -0.722897396012249
      ms.tracked_location = tracked_loc
      ms.face_away_from_target loc, 0.1
      loc.angle_rotated.should == 0
    end
  end
end # describe TracksLocations
end # module MovementStrategies
end # module Motel
