# rotate movement strategy tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

#describe Motel::MovementStrategies::Rotatable do
#end
#
describe Motel::MovementStrategies::Rotatable do

  it "should accept params for angular rotation" do
     rot = Motel::MovementStrategies::Rotate.new :speed => 5, :dtheta => 0.25, :dphi => 0.56
     rot.dtheta = 0.25
     rot.dphi   = 0.56
  end

  it "should return bool indicating validity of movement_strategy" do
     rot = Motel::MovementStrategies::Rotate.new
     rot.valid?.should be_true

     rot.dtheta = :foo
     rot.valid?.should be_false

     rot.dtheta = -0.5
     rot.valid?.should be_false

     rot.dtheta = 9.89
     rot.valid?.should be_false
     rot.dtheta = 0.15

     rot.dphi = :foo
     rot.valid?.should be_false

     rot.dphi = -0.15
     rot.valid?.should be_false

     rot.dphi = 10.22
     rot.valid?.should be_false

     rot.dphi = 0.35
     rot.valid?.should be_true
  end

  it "should rotate location" do
     rot = Motel::MovementStrategies::Rotate.new :speed => 5, :step_delay => 5, :dtheta => 0.11, :dphi => 0.22
     dt,dp  = rot.dtheta, rot.dphi

     parent   = Motel::Location.new
     x = y = z = 20
     orientation  = [1,0,0]
     sorientation = Motel::to_spherical(*orientation)
     location = Motel::Location.new(:parent => parent,
                                    :movement_strategy => rot,
                                    :orientation  => orientation,
                                    :x => x, :y => y, :z => z)

     # move and validate
     rot.move location, 1
     location.orientation.should == Motel.from_spherical(sorientation[0] + dt, sorientation[1] + dp, 1)

     orientation  = location.orientation
     sorientation = location.spherical_orientation

     rot.move location, 5
     location.orientation.should == Motel.from_spherical(sorientation[0] + dt * 5, sorientation[1] + dp * 5, 1)
  end

  it "should not rotate location if strategy is invalid" do
     rot = Motel::MovementStrategies::Rotate.new :dtheta => 0.1
     parent   = Motel::Location.new
     x = y = z = 20
     location = Motel::Location.new(:parent => parent, :movement_strategy => rot,
                                    :x => x, :y => y, :z => z)

     rot.dtheta = -10
     rot.valid?.should be_false

     rot.move location, 5
     location.x.should == x
     location.y.should == y
     location.z.should == z
  end

  it "should be convertable to json" do
    rot = Motel::MovementStrategies::Rotate.new :dtheta => 0.1, :dphi => 0.2, :step_delay => 1

    j = rot.to_json
    j.should include('"json_class":"Motel::MovementStrategies::Rotate"')
    j.should include('"step_delay":1')
    j.should include('"dtheta":0.1')
    j.should include('"dphi":0.2')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Motel::MovementStrategies::Rotate","data":{"step_delay":1,"dtheta":0.1,"dphi":0.2}}'
    m = JSON.parse(j)

    m.class.should == Motel::MovementStrategies::Rotate
    m.step_delay.should == 1
    m.dtheta.should == 0.1
    m.dphi.should == 0.2
  end

end
