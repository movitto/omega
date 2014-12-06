# TracksCoordinates Strategy Mixin Specs
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Motel
module MovementStrategies
describe TracksCoordinates do
  let(:ms)  { Object.new.extend(TracksCoordinates) }
  let(:loc) { Location.new }

  describe "#target_attrs_from_args" do
    it "sets target" do
      target = Object.new
      ms.target_attrs_from_args :target => target
      ms.target.should == target
    end

    it "sets orientation_tolerance" do
      ms.target_attrs_from_args :orientation_tolerance => Math::PI
      ms.orientation_tolerance.should == Math::PI
    end

    it "sets distance_tolerance" do
      ms.target_attrs_from_args :distance_tolerance => CLOSE_ENOUGH / 10
      ms.distance_tolerance.should == CLOSE_ENOUGH / 10
    end
  end

  describe "#target_attrs_valid?" do
    before(:each) do
      ms.target = [1, 2, 3]
    end

    context "targets not an array of length 3" do
      it "returns false" do
        ms.target = :foo
        ms.target_attrs_valid?.should be_false

        ms.target = [1]
        ms.target_attrs_valid?.should be_false
      end
    end

    context "target values are not numeric" do
      it "returns false" do
        ms.target = [:a, :b, :c]
        ms.target_attrs_valid?.should be_false
      end
    end

    it "returns true" do
      ms.target_attrs_valid?.should be_true
    end
  end

  describe "#arrived?" do
    context "distance location is from target > distance_tolerance" do
      it "returns false" do
        loc.coordinates = 0, 100, 0
        ms.distance_tolerance = 50
        ms.target = [0, 25, 0]
        ms.arrived?(loc).should be_false
      end
    end

    context "distance location is from target <= distance_tolerance" do
      it "returns true" do
        loc.coordinates = 0, 10, 0
        ms.distance_tolerance = 50
        ms.target = [0, 25, 0]
        ms.arrived?(loc).should be_true
      end
    end
  end

  describe "#distance_from_target" do
    it "returns distance location is from target" do
      loc.coordinates = 0, 10, 0
      ms.target = [0, 25, 0]
      ms.distance_from_target(loc).should == 15
    end
  end

  describe "#direction_to_target" do
    it "returns direction from location to target" do
      loc.coordinates = [86.54853228027831, -80.38296986263643, 18.531468532077312]
      ms.target       = [-14.15869434587773, -7.001201354703013, 42.70420337041535]
      expected        = [0.7934094302935473, -0.5781291879076614, -0.19044190192942476]

      ms.direction_to_target(loc).should == expected
    end
  end

  describe "#direction_away_from_target" do
    it "returns inverted direction from location to target" do
      loc.coordinates = [86.54853228027831, -80.38296986263643, 18.531468532077312]
      ms.target       = [-14.15869434587773, -7.001201354703013, 42.70420337041535]
      expected        = [-0.7934094302935473, 0.5781291879076614, 0.19044190192942476]

      ms.direction_away_from_target(loc).should == expected
    end
  end

  describe "#rotation_to" do
    it "returns rotation from location to specified coordinate" do
      loc.coordinates = -48.82439586945394, -20.746429108250474, -4.719402737865752
      loc.orientation = -0.43685202833051895, 0.7863336509949341, -0.43685202833051895
      coords          = [93.45902010596238, -13.28750216079121, -20.83296948016048]
      expected        = [1.9214292116942426, -0.06989454499105958, -0.5138469070103436, -0.8550298876275589]
      ms.rotation_to(loc, coords).should == expected
    end
  end

  describe "#rotation_to_target" do
    it "returns rotation from location to target" do
      loc.coordinates = [-37.021550276334146, -64.08039699054616, -82.1363871356402]
      loc.orientation = -0.7682212795973759, 0.0, 0.6401843996644799
      ms.target       = [-19.152712096271294, 87.7336545367796, -0.21911815935840018]
      expected        = [1.3456658037137743, -0.5749077264794487, 0.4399248785003237, -0.6898892717753383]
      ms.rotation_to_target(loc).should == expected
    end
  end

  describe "#orientation_difference" do
    it "returns rotation from location's orientation to specified orientation" do
      loc.orientation = 0.9922778767136677, 0.12403473458920847, 0.0
      orientation     = [0.22941573387056174, -0.6882472016116852, 0.6882472016116852]
      expected        = [1.4280342835350706, 0.08624393618641034, -0.6899514894912827, -0.7186994682200862]
      ms.orientation_difference(loc, orientation).should == expected
    end
  end

  describe "#facing?" do
    context "rotation from location to coordinates is > orientation tolerance" do
      it "returns false" do
        ms.orientation_tolerance = Math::PI / 8
        loc.coordinates = -26.765010714330472, 40.94477360837112, 70.45487586571232
        loc.orientation = -0.8320502943378436, -0.554700196225229, 0.0
        coords          = [-64.73390753545335, -71.81018580665636, 9.09032123567558]
        ms.facing?(loc, coords).should be_false
      end
    end

    context "rotation from location to coordinates is <= orientation tolerance" do
      it "returns true" do
        ms.orientation_tolerance = Math::PI / 8
        loc.coordinates = -35.30849735218048,   45.17637940939163,   7.759298141428539
        loc.orientation =   0.6859943405700353, -0.5144957554275265, 0.5144957554275265
        coords          = [-1.008780323678721,  19.451591638015305, 33.484085912804865]
        ms.facing?(loc, coords).should be_true
      end
    end
  end

  describe "#facing_target?" do
    context "location is not facing target" do
      it "returns false" do
        ms.orientation_tolerance = Math::PI / 8
        loc.coordinates = -64.2532421714741, -67.09501511988817, 11.646830708347899
        loc.orientation = 0.7844645405527362, -0.19611613513818404, 0.5883484054145521
        ms.target       = [-99.70641357394929, -45.20763829062688, 60.57768253749668]
        ms.facing_target?(loc).should be_false
      end
    end

    context "location is facing target" do
      it "returns true" do
        ms.orientation_tolerance = 0
        loc.coordinates = 8.472235962936836, -47.93690617226565, -62.459485828959615
        loc.orientation = 0.5366563145999494, 0.4472135954999579, -0.7155417527999327
        ms.target       = [5375.0353819624315, 4424.199048827314, -7217.877013828286]
        ms.facing_target?(loc).should be_true
      end
    end
  end

  describe "#face_target" do
    before(:each) do
      ms.extend(Rotatable)
    end

    it "inits rotation from rotation to target" do
      rotation = [0.88, 0.9363291775690445, -0.3511234415883917, 0.0]
      ms.rot_theta = 0.75
      ms.should_receive(:rotation_to_target)
        .with(loc)
        .and_return(rotation)

      ms.face_target(loc)
      ms.rot_theta.should == 0.75
      ms.rot_dir.should == rotation[1..3]
      ms.stop_angle.should == rotation[0].abs
    end

    it "resets angle rotated" do
      loc.angle_rotated = Math::PI
      loc.coordinates = -54.449001224309704, -77.0955674026169, 93.61492221297951
      loc.orientation = -0.5232045649263551, 0.5232045649263551, -0.6726915834767423
      ms.target       = [36.66661735857656, 94.47067872011982, 51.84824154157957]

      ms.face_target(loc)
      loc.angle_rotated.should == 0
    end
  end

  describe "#face" do
    before(:each) do
      ms.extend(Rotatable)
    end

    it "inits rotation from orientation difference" do
      loc.orientation = -0.29138575870717925, -0.8741572761215377, -0.38851434494290565
      orientation     = [0.5261522196019802,  -0.6013168224022631,  0.6013168224022631]
      diff = loc.orientation_difference(*orientation)
      ms.rot_theta = 1.59

      ms.face(loc, orientation)
      ms.rot_theta.should == 1.59
      ms.rot_dir.should == diff[1..3]
      ms.stop_angle.should == diff[0].abs
    end

    it "resets angle rotated" do
      loc.angle_rotated = 1.11
      loc.orientation =  0.0, 0.40613846605344767, -0.9138115486202573
      orientation     = [0.8017837257372732, 0.5345224838248488, 0.2672612419124244]
      ms.rot_theta = 2.11

      ms.face(loc, orientation)
      loc.angle_rotated.should == 0
    end
  end

  describe "#target_json" do
    it "returns target json data hash" do
      ms.target_json.should be_an_instance_of(Hash)
    end

    it "returns target in target json data hash" do
      ms.target = [1, 2, 3]
      ms.target_json[:target].should == ms.target
    end

    it "returns orientation tolerance in target json data hash" do
      ms.orientation_tolerance = Math::PI / 5
      ms.target_json[:orientation_tolerance].should == Math::PI/5
    end

    it "returns distance tolerance in target json data hash" do
      ms.distance_tolerance = 50
      ms.target_json[:distance_tolerance].should == 50
    end
  end
end # describe TracksCoordinates
end # module MovementStrategies
end # module Motel
