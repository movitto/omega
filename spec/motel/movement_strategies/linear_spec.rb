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
      linear = Linear.new :rot_theta => 0.25, :rot_x => 0.56
      linear.rot_theta.should == 0.25
      linear.rot_x.should   == 0.56
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
        linear.rot_theta = :foo
        linear.should_not be_valid

        linear.rot_theta = 0.15
        linear.rot_x = :foo
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
                          :rot_theta => 0.11
      dt = linear.rot_theta

      p   = Motel::Location.new
      x = y = z = 20
      orientation  = [1,0,0]
      l = Motel::Location.new(:parent => p,
                              :movement_strategy => linear,
                              :orientation  => orientation,
                              :x => x, :y => y, :z => z)
      ol = Motel::Location.new :orientation => orientation

      # move and validate
      linear.move l, 1
      l.orientation.should ==
        l.ms.rotate(ol, 1)

      orientation  = l.orientation

      linear.move l, 5
      l.orientation.should ==
        l.ms.rotate(ol, 5)
    end
  end

  describe "#to_json" do
    it "returns linear in json format" do
      m = Linear.new :step_delay => 20,
                       :speed      => 15,
                       :rot_theta  => 5.14,
                       :rot_x      => -1,
                       :rot_y      =>  0,
                       :rot_z      =>  0,
                       :dx =>  1,
                       :dz =>  0,
                       :dz =>  0
      j = m.to_json
      j.should include('"json_class":"Motel::MovementStrategies::Linear"')
      j.should include('"step_delay":20')
      j.should include('"speed":15')
      j.should include('"rot_theta":5.14')
      j.should include('"rot_x":-1')
      j.should include('"rot_y":0')
      j.should include('"rot_z":0')
      j.should include('"dx":1')
      j.should include('"dy":0')
      j.should include('"dz":0')
    end
  end

  describe "#json_create" do
    it "returns linear from json format" do
      j = '{"json_class":"Motel::MovementStrategies::Linear","data":{"speed":15,"dx":1,"dy":0,"step_delay":20,"dz":0,"rot_theta":5.14,"rot_x":-1,"rot_y":0,"rot_z":0}}'
      m = RJR.parse_json(j)

      m.class.should == Motel::MovementStrategies::Linear
      m.step_delay.should == 20
      m.speed.should == 15
      m.dx.should == 1
      m.dy.should == 0
      m.dz.should == 0
      m.rot_theta.should == 5.14
      m.rot_x.should == -1
      m.rot_y.should == 0
      m.rot_z.should == 0
    end
  end

end # describe Linear
end # module Motel::MovementStrategies
