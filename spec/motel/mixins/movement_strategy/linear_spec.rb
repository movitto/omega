# Linear Movement Strategy Mixin Specs
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Motel
module MovementStrategies
describe LinearMovement do
  let(:ms)  { Object.new.extend(LinearMovement) }
  let(:loc) { Location.new }

  describe "#dir" do
    it "returns movement direction array" do
      ms.dx = 1
      ms.dy = 0
      ms.dz = 0
      ms.dir.should == [1, 0, 0]
    end
  end

  describe "#dir=" do
    it "sets movement direction array" do
      ms.dir = [0, 1, 0]
      ms.dx.should == 0
      ms.dy.should == 1
      ms.dz.should == 0

      ms.dir = 0.1, 0.2, 0.3
      ms.dx.should == 0.1
      ms.dy.should == 0.2
      ms.dz.should == 0.3
    end
  end

  describe "#adir" do
    it "returns acceleration direction" do
      ms.ax = 0
      ms.ay = 1
      ms.az = 0
      ms.adir.should == [0, 1, 0]
    end
  end

  describe "#adir=" do
    it "sets movement direction array" do
      ms.adir = [0, 1, 0]
      ms.ax.should == 0
      ms.ay.should == 1
      ms.az.should == 0

      ms.adir = 0.1, 0.2, 0.3
      ms.ax.should == 0.1
      ms.ay.should == 0.2
      ms.az.should == 0.3
    end
  end


  describe "#linear_attrs_from_args" do
    it "initializes direction" do
      ms.linear_attrs_from_args :dx => 0, :dy => 0, :dz => 1
      ms.dir.should == [0, 0, 1]
    end

    it "initializes acceleration direction" do
      ms.linear_attrs_from_args :ax => 0, :ay => 0, :az => 1
      ms.adir.should == [0, 0, 1]
    end

    it "initializes speed" do
      ms.linear_attrs_from_args :speed => 42
      ms.speed.should == 42
    end

    it "initializes acceleration" do
      ms.linear_attrs_from_args :acceleration => 42
      ms.acceleration.should == 42
    end

    it "initializes stop_distance" do
      ms.linear_attrs_from_args :stop_distance => 200
      ms.stop_distance.should == 200
    end

    it "initializes stop_near" do
      stop_near = [0, 100, 100, 100]
      ms.linear_attrs_from_args :stop_near => stop_near
      ms.stop_near.should == stop_near
    end

    it "initializes max_speed" do
      ms.linear_attrs_from_args :max_speed => 1024
      ms.max_speed.should == 1024
    end

    it "normalizes direction" do
      dir = [0.5, 0.75, 0.25]
      ndir = Motel.normalize(*dir)
      ms.linear_attrs_from_args :dx => dir[0], :dy => dir[1], :dz => dir[2]
      ms.dir.should == ndir
    end

    it "normalizes acceleration direction" do
      adir = [12.5, 15.75, -17.56]
      ndir = Motel.normalize(*adir)
      ms.linear_attrs_from_args :ax => adir[0], :ay => adir[1], :az => adir[2]
      ms.adir.should == ndir
    end

    it "sets defaults"
  end

  describe "#linear_attrs_valid?" do
    before(:each) do
      ms.dir = 1, 0, 0
      ms.speed = 42
    end

    context "direction not normalized" do
      it "returns false" do
        ms.dx = 5
        ms.linear_attrs_valid?.should be_false
      end
    end

    context "speed is not valid" do
      it "returns false" do
        ms.should_receive(:speed_valid?).and_return(false)
        ms.linear_attrs_valid?.should be_false
      end
    end

    context "acceleration is set and not valid" do
      it "returns false" do
        ms.acceleration = 50
        ms.should_receive(:acceleration_valid?).and_return(false)
        ms.linear_attrs_valid?.should be_false
      end
    end

    it "returns true" do
      ms.linear_attrs_valid?.should be_true
    end
  end

  describe "#speed_valid?" do
    context "speed is not numeric" do
      it "returns false" do
        ms.speed = :a
        ms.speed_valid?.should be_false

        ms.speed = nil
        ms.speed_valid?.should be_false

        ms.speed = '5'
        ms.speed_valid?.should be_false
      end
    end

    context "speed <= 0" do
      it "returns false" do
        ms.speed = -5
        ms.speed_valid?.should be_false

        ms.speed = 0
        ms.speed_valid?.should be_false
      end
    end
    
    it "returns true" do
      ms.speed = 5
      ms.speed_valid?.should be_true
    end
  end

  describe "#acceleration_valid?" do
    before(:each) do
      ms.ax = 1
      ms.ay = ms.az = 0
    end

    context "acceleration is not numeric" do
      it "returns false" do
        ms.acceleration = :a
        ms.acceleration_valid?.should be_false

        ms.acceleration = '5'
        ms.acceleration_valid?.should be_false

        # note linear_attrs_valid? allows acceleration to be nil
        ms.acceleration = nil
        ms.acceleration_valid?.should be_false
      end
    end

    context "acceleration <= 0" do
      it "returns false" do
        ms.acceleration = 0
        ms.acceleration_valid?.should be_false

        ms.acceleration = -5
        ms.acceleration_valid?.should be_false
      end
    end

    context "acceleration direction not normalized" do
      it "returns false" do
        ms.ax = 50
        ms.acceleration_valid?.should be_false
      end
    end

    it "returns true" do
      ms.acceleration = 5
      ms.acceleration_valid?.should be_true
    end
  end

  describe "#stop_distance_exceeded?" do
    context "stop_distance is nil" do
      it "returns false" do
        ms.stop_distance_exceeded?(loc).should be_false
      end
    end

    context "loc.distance_moved < stop_distance" do
      it "returns false" do
        loc.distance_moved = 5
        ms.stop_distance = 10
        ms.stop_distance_exceeded?(loc).should be_false
      end
    end

    context "loc.distance_moved >= set stop_distance" do
      it "returns true" do
        loc.distance_moved = 50
        ms.stop_distance = 10
        ms.stop_distance_exceeded?(loc).should be_true
      end
    end
  end

  describe "#exceeds_stop_distance?" do
    context "stop_distance is nil" do
      it "returns false" do
        ms.exceeds_stop_distance?(loc, 1).should be_false
      end
    end

    context "loc.distance_moved + distance <= stop_distance" do
      it "returns false" do
        loc.distance_moved = 10
        ms.stop_distance   = 20
        ms.exceeds_stop_distance?(loc, 1).should be_false
      end
    end

    context "loc.distance_moved + distance > stop_distance" do
      it "returns true" do
        loc.distance_moved = 20
        ms.stop_distance   = 20
        ms.exceeds_stop_distance?(loc, 1).should be_true

        ms.stop_distance   = 30
        ms.exceeds_stop_distance?(loc, 20).should be_true
      end
    end
  end

  describe "#distance_from_stop" do
    it "returns distance location is from stop_near" do
      loc.coordinates = [10, 10, 10]
      ms.stop_near = [0, 20, 20, 20]
      expected = loc.distance_from(*ms.stop_near[1..3])
      ms.distance_from_stop(loc).should == expected
    end
  end

  describe "#near_stop_coordinate?" do
    context "stop_near is nil" do
      it "returns false" do
        ms.near_stop_coordinate?(loc).should be_false
      end
    end

    context "distance_from stop > stop distance" do
      it "returns false" do
        loc.coordinates = [-200, 0, 100]
        ms.stop_near    = [1, 100, 100, 100]
        ms.near_stop_coordinate?(loc).should be_false
      end
    end

    context "distance_from stop <= stop distance" do
      it "returns true" do
        loc.coordinates = [0, 0, 0]
        ms.stop_near    = [10, 5, 0, 0]
        ms.near_stop_coordinate?(loc).should be_true
      end
    end
  end

  describe "#exceeds_stop_coordinate?" do
    context "stop_near is nil" do
      it "returns false" do
        ms.exceeds_stop_coordinate?(loc, 1).should be_false
      end
    end

    context "specified distance <= distance location is from stop" do
      it "returns false" do
        loc.coordinates = [10, 20, 10]
        ms.stop_near    = [0, 10, 0, 10]
        ms.exceeds_stop_coordinate?(loc, 5).should be_false
      end
    end

    context "specified distance > distance location is from stop" do
      it "returns true" do
        loc.coordinates = [10, 20, 10]
        ms.stop_near    = [0, 10, 0, 10]
        ms.exceeds_stop_coordinate?(loc, 30).should be_true
      end
    end
  end

  describe "#facing_movement?" do
    context "rotation of orientation to face direction is > tolerance" do
      it "returns false" do
        loc.orientation = [0, 0, 1]
        ms.dir = 0, 0, -1
        ms.facing_movement?(loc, Math::PI/2).should be_false
      end
    end

    context "rotation of orientation to face direction is <= tolerance" do
      it "returns true" do
        loc.orientation = [0, 0, 1]
        ms.dir = 0, 1, 0
        ms.facing_movement?(loc, Math::PI).should be_true
      end
    end
  end

  describe "#linear_json" do
    it "returns linear attributes json data hash" do
      ms.linear_json.should be_an_instance_of(Hash)
    end

    it "returns speed in json data hash" do
      ms.speed = 42
      ms.linear_json[:speed].should == 42
    end

    it "returns direction in json data hash" do
      ms.dir = 0.7, 0.5, 0.3
      ms.linear_json[:dx].should == 0.7
      ms.linear_json[:dy].should == 0.5
      ms.linear_json[:dz].should == 0.3
    end

    it "returns acceleration in json data hash" do
      ms.acceleration = 42
      ms.linear_json[:acceleration].should == 42
    end

    it "returns acceleration direction in json data hash" do
      ms.ax = -0.7
      ms.ay = -0.5
      ms.az = -0.3
      ms.linear_json[:ax].should == -0.7
      ms.linear_json[:ay].should == -0.5
      ms.linear_json[:az].should == -0.3
    end

    it "returns stop distance in json data hash" do
      ms.stop_distance = 123
      ms.linear_json[:stop_distance].should == 123
    end

    it "returns stop near in json data hash" do
      ms.stop_near = [0, 1, 2, -3]
      ms.linear_json[:stop_near].should == [0, 1, 2, -3]
    end

    it "returns max_speed in json data hash" do
      ms.max_speed = 1000
      ms.linear_json[:max_speed].should == 1000
    end
  end

  describe "#update_dir_from" do
    it "sets direction from location orientation" do
      loc.orientation = [0.9, 0.1, 0]
      ms.update_dir_from(loc)
      ms.dir.should == [0.9, 0.1, 0]
    end
  end

  describe "#update_acceleration_from" do
    it "sets acceleration from location orientation" do
      loc.orientation = [0.9, 0.1, 0]
      ms.update_acceleration_from(loc)
      ms.adir.should == [0.9, 0.1, 0]
    end

    it "sets acceleration from specified array" do
      accel = [0.2, -0.3, 0.77]
      ms.update_acceleration_from(accel)
      ms.adir.should == accel
    end
  end

  describe "#acceleration_component" do
    it "returns component of acceleration for specified time" do
      ms.acceleration = 50
      ms.acceleration_component(0.25).should == 50 * 0.25
    end
  end

  describe "#accelerate" do
    it "adjusts speed by accelerating over the specified time" do
      ms.dx =  0.6359987280038161
      ms.dy =  0.211999576001272
      ms.dz = -0.741998516004452
      ms.speed = 100

      ms.ax =  0.8700628401410972 
      ms.ay =  0.09667364890456637
      ms.az = -0.48336824452283184
      ms.acceleration = 1000

      ms.accelerate 0.01
      ms.speed.should == 109.38475352910028
      ms.dir.should   == [0.6609742113882264, 0.20264884615090098, -0.7225278797620343]
    end

    it "caps speed at max speed" do
      ms.dx = ms.ax = -0.6556100681071858
      ms.dy = ms.ay =  0.7492686492653552
      ms.dz = ms.az =  0.0936585811581694
      ms.speed = 42
      ms.max_speed = 43
      ms.acceleration = 1000

      ms.accelerate 0.01
      ms.speed.should == 43
      ms.dir.should   == [-0.6556100681071858, 0.7492686492653551, 0.09365858115816939]
    end
  end

  describe "#move_linear" do
    before(:each) do
      loc.distance_moved = 0
      loc.coordinates = 0, 0, 0
      ms.dir = 1, 0, 0
      ms.speed = 50
    end

    context "acceleration is nil" do
      it "does not accelerate" do
        ms.should_not_receive(:accelerate)
        ms.move_linear(loc, 0.01)
      end
    end

    it "accelerates" do
      ms.acceleration = 50
      ms.should_receive(:accelerate)
      ms.move_linear(loc, 0.01)
    end

    context "exceeds_stop_distance" do
      it "reduces distance location moves to remaining distance" do
        ms.stop_distance = 50
        loc.distance_moved = 40
        ms.speed = 200

        ms.dir = 1, 0, 0
        loc.coordinates = [0, 0, 0]
        ms.move_linear(loc, 0.1)
        loc.coordinates.should == [10, 0, 0]
      end
    end

    context "near stop coordinate" do
      it "does not move location" do
        ms.stop_near = [100, 10, 10, 10]
        loc.coordinates = [50, 50, 50]
        ms.move_linear(loc, 0.1)
        loc.coordinates.should == [50, 50, 50]
      end
    end

    context "exceeds stop coordinate" do
      it "reduces distance location moves to distance from stop" do
        loc.coordinates = [0, 0, -20]
        ms.stop_near = [10, 0, 0, 0]
        ms.speed = 500
        ms.dir = [0, 0, 1]
        ms.move_linear(loc, 0.1)
        loc.coordinates.should == [0, 0, 0]
      end
    end

    it "moves location by speed/direction for specified time" do
      loc.coordinates = [-155.76614537956257, -373.2398391462362, 472.82481122181895]
      ms.speed = 42.208373935245874
      ms.acceleration = 7.875664251364178
      ms.dir  = -0.4444444444444444, 0.8888888888888888, -0.1111111111111111
      ms.adir =  0.6359987280038161, 0.741998516004452,  -0.211999576001272
      ms.move_linear(loc, 0.1)

      ms.speed.should == 42.529873086764596
      ms.dir.should == [-0.42930732529344184, 0.8959097444302349, -0.11419698018924095]
      loc.coordinates.should == [-157.59198398555742, -369.42954637345485, 472.33913291438495]
    end

    it "updates location distance_moved" do
      loc.coordinates = 148.27005233076196, 81.43521582409058, -424.33445249243823
      ms.speed = 24.56622162691466
      ms.acceleration = 44.853362875634282
      ms.dir = [-0.7525766947068778, 0.0, 0.658504607868518]
      ms.adir = [-0.4472135954999579, -0.8944271909999159, 0.0]

      ms.move_linear(loc, 0.1)
      loc.distance_moved.should == 2.641567021046574
      ms.move_linear(loc, 0.1)
      loc.distance_moved.should == 5.526549696104695
    end
  end
end # describe LinearMovement
end # module MovementStrategies
end # module Motel
