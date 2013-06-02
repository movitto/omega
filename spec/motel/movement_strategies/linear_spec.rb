# linear movement strategy tests
#
# Copyright (C) 2009-2013 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/location'
require 'motel/movement_strategies/linear'

module Motel::MovementStrategies
describe Linear do
  describe "#initialize" do
    it "sets defaults" do
      linear = Linear.new
      linear.dx.should == 1
      linear.dy.should == 0
      linear.dz.should == 0
      linear.speed.should == nil
    end

    it "sets attributes" do
      linear = Linear.new :dx => 1,
                          :dy => 2,
                          :dz => 3, :speed => 5

      # ensure linear vector gets automatically normailized
      dx,dy,dz = Motel.normalize 1,2,3
      linear.dx.should == dx
      linear.dy.should == dy
      linear.dz.should == dz

      linear.speed.should == 5
    end

    it "sets rotation attributes" do
      linear = Linear.new :dtheta => 0.25, :dphi => 0.56
      linear.dtheta.should == 0.25
      linear.dphi.should   == 0.56
    end
  end

  describe "#valid?" do
    context "direction not normalized" do
      it "returns false" do
        linear = Linear.new :speed => 5,
                            :dx => 1,
                            :dy => 0,
                            :dz => 0
        linear.dx = 10
        linear.should_not be_valid
      end
    end

    context "speed is not numeric" do
      it "returns false" do
        linear = Linear.new :speed => "10"
        linear.should_not be_valid
      end
    end

    context "speed is <= 0" do
      it "returns false" do
        linear = Linear.new :speed => -5
        linear.should_not be_valid
      end
    end

    context "rotation is not valid" do
      it "returns false" do
        linear = Linear.new :speed => 5
        linear.dtheta = :foo
        linear.should_not be_valid

        linear.dtheta = 0.15
        linear.dphi = :foo
        linear.should_not be_valid
      end
    end

    context "linear is valid" do
      it "return true" do
        linear = Linear.new :speed => 5
        linear.should be_valid

        linear = Linear.new
        linear.speed = 5
        linear.should be_valid
      end
    end
  end

  describe "#move" do
    before(:each) do
      @l = Motel::Location.new
    end

    context "linear not valid" do
      it "does not move location" do
        linear = Linear.new
        linear.speed = -5

        lambda {
          linear.move @l, 1
        }.should_not change(@l, :coordinates)
      end
    end

    it "moves location in direction by speed * elapsed_time" do
      linear = Linear.new :step_delay => 5, :speed => 20, 
                          :dx => 5,
                          :dy => 5,
                          :dz => 5

      dx,dy,dz = linear.dx,
                 linear.dy,
                 linear.dz

      p   = Motel::Location.new
      x = y = z = 20
      l = Motel::Location.new(:parent => p,
                              :movement_strategy => linear,
                              :x => x, :y => y, :z => z)

      # move and validate
      linear.move l, 1
      l.x.should == x + dx * linear.speed
      l.y.should == y + dy * linear.speed
      l.z.should == z + dz * linear.speed

      x = l.x
      y = l.y
      z = l.z

      linear.move l, 5
      l.x.should == x + dx * linear.speed * 5
      l.y.should == y + dy * linear.speed * 5
      l.z.should == z + dz * linear.speed * 5
    end

    it "rotates location" do
      linear = Linear.new :speed => 5, :step_delay => 5,
                          :dtheta => 0.11, :dphi => 0.22
      dt,dp  = linear.dtheta, linear.dphi

      p   = Motel::Location.new
      x = y = z = 20
      orientation  = [1,0,0]
      sorientation = Motel::to_spherical(*orientation)
      l = Motel::Location.new(:parent => p,
                              :movement_strategy => linear,
                              :orientation  => orientation,
                              :x => x, :y => y, :z => z)

      # move and validate
      linear.move l, 1
      l.orientation.should ==
        Motel.from_spherical(sorientation[0] + dt,
                             sorientation[1] + dp, 1)

      orientation  = l.orientation
      sorientation = l.spherical_orientation

      linear.move l, 5
      l.orientation.should ==
        Motel.from_spherical(sorientation[0] + dt * 5,
                             sorientation[1] + dp * 5, 1)
    end
  end

  describe "#to_json" do
    it "returns linear in json format" do
      m = Linear.new :step_delay => 20,
                       :speed      => 15,
                       :dtheta     => 5.14,
                       :dphi       => 2.22,
                       :dx =>  1,
                       :dz =>  0,
                       :dz =>  0
      j = m.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Linear"')
      j.should include('"step_delay":20')
      j.should include('"speed":15')
      j.should include('"dtheta":5.14')
      j.should include('"dphi":2.22')
      j.should include('"dx":1')
      j.should include('"dy":0')
      j.should include('"dz":0')
    end
  end

  describe "#json_create" do
    it "returns linear from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Linear","data":{"speed":15,"dx":1,"dy":0,"step_delay":20,"dz":0,"dtheta":5.14,"dphi":2.22}}'
      m = JSON.parse(j)

      m.class.should == Motel::MovementStrategies::Linear
      m.step_delay.should == 20
      m.speed.should == 15
      m.dx.should == 1
      m.dy.should == 0
      m.dz.should == 0
      m.dtheta.should == 5.14
      m.dphi.should == 2.22
    end
  end

end # describe Linear
end # module Motel::MovementStrategies
