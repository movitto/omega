# Elliptical Movement Mixin Tests
#
# Copyright (C) 2009-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

module Motel::MovementStrategies
describe EllipticalMovement do
  let(:movement) { Object.new.extend(EllipticalMovement)
                             .extend(EllipticalPath)
                             .extend(EllipticalAxis) }
  let(:loc)      { build(:location) }

  describe "#movement_from_args" do
    it "initializes speed" do
      movement.movement_from_args :speed => 50
      movement.speed.should == 50
    end

    it "initializes path_tolerance" do
      movement.movement_from_args :path_tolerance => 50
      movement.path_tolerance.should == 50
    end

    it "sets defaults" do
      movement.movement_from_args({})
      movement.speed.should be_nil
      movement.path_tolerance.should == 0
    end
  end

  describe "#elliptical_speed_valid?" do
    before(:each) do
      movement.speed = 10
      movement.path_tolerance = 50
    end

    context "speed is not numeric" do
      it "returns false" do
        movement.speed = :a
        movement.elliptical_speed_valid?.should be_false
      end
    end

    context "speed is <= 0" do
      it "returns false" do
        movement.speed = 0
        movement.elliptical_speed_valid?.should be_false

        movement.speed = -1
        movement.elliptical_speed_valid?.should be_false
      end
    end

    context "path tolerance is not numeric" do
      it "returns false" do
        movement.path_tolerance = :a
        movement.elliptical_speed_valid?.should be_false
      end
    end
    
    context "path_tolerance < 0" do
      it "returns false" do
        movement.path_tolerance = -1
        movement.elliptical_speed_valid?.should be_false
      end
    end

    it "returns true" do
      movement.elliptical_speed_valid?.should be_true
    end
  end

  describe "#movement_json" do
    it "returns elliptical movement json data hash" do
      movement.movement_json.should be_an_instance_of(Hash)
    end

    it "returns speed in json data" do
      movement.speed = 50
      movement.movement_json[:speed].should == 50
    end

    it "returns path_tolerance in json data" do
      movement.path_tolerance = 123
      movement.movement_json[:path_tolerance].should == 123
    end
  end

  describe "#move_elliptical" do
    before(:each) do
      movement.e = 0.5
      movement.p = 100
      movement.center = 0, 0, 0
      movement.axis_from_args({})
      movement.path_tolerance = 100
    end

    context "location is not valid in context of path" do
      it "moves location to closest coordinates on path" do
        expected = movement.coordinates_from_theta(movement.theta(loc))
        movement.speed = 0
        movement.should_receive(:location_valid?)
                .with(loc).and_return(false)
        movement.should_receive(:closest_coordinates)
                .with(loc).and_return(expected)
        movement.move_elliptical(loc, 1)
        loc.coordinates.should == expected
      end
    end

    it "moves location along path" do
      loc.coordinates = movement.coordinates_from_theta(movement.theta(loc))
      movement.speed  = Math::PI/7
      elapsed         = 0.1
      expected        = movement.coordinates_from_theta(movement.theta(loc) +
                                                        movement.speed * elapsed)
      movement.move_elliptical(loc, elapsed)
      loc.coordinates.should == expected
    end
  end

  describe "#origin_centered_coordinates" do
    it "returns location coordinates - center" do
      center = [99, -88, -77]
      movement.center = center
      result = movement.origin_centered_coordinates(loc)
      result.should == [loc.x - 99, loc.y + 88, loc.z + 77]
    end
  end

  describe "#theta" do
    before(:each) do
      dmaj = [ 0.7915188128216208, 0.174248312621674,  -0.5857776835096667]
      dmin = [-0.2786764693920024, 0.9559496501625963, -0.09219377289827294]

      movement.relative_to = Elliptical::FOCI
      movement.e = 0.7211213605776564
      movement.p = 5000000
      movement.center = 1000, 2000, -500
      movement.axis_from_args(:direction => [*dmaj, *dmin])
      movement.path_tolerance = 100
    end

    it "returns angle location is at on elliptical path" do
      loc.coordinates = [-0.26490647141300877, 0.9271726499455306, -0.26490647141300877]
      movement.theta(loc).should == 4.7122514364405115
    end
  end

  describe "#coordinates_from_theta" do
    before(:each) do
      dmaj = [-0.8271328777286014,   0.40532672936054426, 0.38930893265668404]
      dmin = [-0.07613737622523581, -0.7671421464033473,  0.6369427188948802] 

      movement.relative_to = Elliptical::FOCI
      movement.e = 0.459114826106538
      movement.p = 3390013000
      movement.center = [1987948.2507331115, -1574609.5612284932, 2139676.13117826]
      movement.axis_from_args(:direction => [*dmaj, *dmin])
      movement.path_tolerance = 5
    end


    it "returns coordinates cooresponding to path angle" do
      movement.coordinates_from_theta(0).should            == [-3550904819.817338, 1739478665.2214007, 1674389599.4791384]
      movement.coordinates_from_theta(Math::PI/9).should   == [-3436008800.2297206, 633255460.4042946, 2404837471.8363996]
      movement.coordinates_from_theta(Math::PI/8).should   == [-3391640798.186746, 486686904.2278428, 2477228172.343761]
      movement.coordinates_from_theta(Math::PI/7).should   == [-3325117265.896797, 296915175.5418444, 2563360694.3277907]
      movement.coordinates_from_theta(Math::PI/4).should   == [-2715727563.232241, -840438246.1384571, 2903256958.393108]
      movement.coordinates_from_theta(Math::PI/2).should   == [-288549418.69215083, -2928960216.1729894, 2432689159.393014]
      movement.coordinates_from_theta(Math::PI).should     == [3554880716.3188033, -1742627884.343858, -1670110247.2167811]
      movement.coordinates_from_theta(3*Math::PI/4).should == [2308821575.0269113, -3302659400.150142, 538338437.1170539]
      movement.coordinates_from_theta(2*Math::PI).should   == [-3550904819.8173375, 1739478665.2214012, 1674389599.479138]
    end
  end

  describe "#closest_coordinates" do
    it "returns coordinates cooresponding to path angle calculated from location's coordinates" do
      theta = Math::PI
      movement.should_receive(:theta)
              .with(loc).and_return(theta)


      expected = [1, 2, -0.4]
      movement.should_receive(:coordinates_from_theta)
              .with(theta).and_return(expected)
      movement.closest_coordinates(loc).should == expected
    end

    context "theta is NaN" do
      it "returns nil" do
        movement.should_receive(:theta).with(loc).and_return(Float::NAN)
        movement.closest_coordinates(loc).should be_nil
      end
    end
  end

  describe "#location_valid?" do
    context "closest path coordinates are undefined" do
      it "returns false" do
        movement.should_receive(:closest_coordinates)
                .with(loc).and_return(nil)
        movement.location_valid?(loc).should be_false
      end
    end

    context "location is not within path tolerance of closest path coordinates" do
      it "returns true" do
        loc.coordinates = [0, 0, 0]
        movement.path_tolerance = 200
        movement.should_receive(:closest_coordinates)
                .with(loc).and_return([100, 0, 0])
        movement.location_valid?(loc).should be_true
      end
    end

    context "location is within path tolerance of closest path coordinates" do
      it "returns true" do
        loc.coordinates = [0, 0, 0]
        movement.path_tolerance = 50
        movement.should_receive(:closest_coordinates)
                .with(loc).and_return([100, 0, 0])
        movement.location_valid?(loc).should be_false
      end
    end
  end
end # describe ElliptcialMovement
end # module Motel::MovementStrategies
