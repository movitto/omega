# linear movement strategy tests
#
# Copyright (C) 2009-2012 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

describe "Motel::MovementStrategies::Linear" do

  it "should successfully accept and set linear params" do
     linear = Motel::MovementStrategies::Linear.new :direction_vector_x => 1, :direction_vector_y => 2, :direction_vector_z => 3, :speed => 5

     # ensure linear vector gets automatically normailized
     dx,dy,dz = Motel.normalize 1,2,3
     linear.direction_vector_x.should == dx
     linear.direction_vector_y.should == dy
     linear.direction_vector_z.should == dz

     linear.speed.should == 5
  end

  it "should accept params for angular rotation" do
     linear = Motel::MovementStrategies::Linear.new :speed => 5, :dtheta => 0.25, :dphi => 0.56
     linear.dtheta = 0.25
     linear.dphi   = 0.56
  end

  it "should return bool indicating validity of movement_strategy" do
     linear = Motel::MovementStrategies::Linear.new :speed => 10
     linear.valid?.should be_true

     linear.speed = 'foobar'
     linear.valid?.should be_false

     linear.speed = -10
     linear.valid?.should be_false
     linear.speed = 10

     linear.direction_vector_x = nil
     linear.valid?.should be_false
     linear.direction_vector_x = 1

     linear.direction_vector_y = nil
     linear.valid?.should be_false
     linear.direction_vector_y = 0

     linear.direction_vector_z = nil
     linear.valid?.should be_false
     linear.direction_vector_z = 0

     linear.direction_vector_x = 10
     linear.valid?.should be_false
     linear.direction_vector_x = 1

     linear.dtheta = :foo
     linear.valid?.should be_false

     linear.dtheta = -0.5
     linear.valid?.should be_false

     linear.dtheta = 9.89
     linear.valid?.should be_false
     linear.dtheta = 0.15

     linear.dphi = :foo
     linear.valid?.should be_false

     linear.dphi = -0.15
     linear.valid?.should be_false

     linear.dphi = 10.22
     linear.valid?.should be_false

     linear.dphi = 0.35
     linear.valid?.should be_true
  end


  it "should move location correctly" do
     linear = Motel::MovementStrategies::Linear.new :step_delay => 5, :speed => 20, 
                         :direction_vector_x => 5, :direction_vector_y => 5, :direction_vector_z => 5
     dx,dy,dz = linear.direction_vector_x, linear.direction_vector_y, linear.direction_vector_z

     parent   = Motel::Location.new
     x = y = z = 20
     location = Motel::Location.new(:parent => parent,
                                    :movement_strategy => linear,
                                    :x => x, :y => y, :z => z)

     # move and validate
     linear.move location, 1
     location.x.should == x + dx * linear.speed
     location.y.should == y + dy * linear.speed
     location.z.should == z + dz * linear.speed

     x = location.x
     y = location.y
     z = location.z

     linear.move location, 5
     location.x.should == x + dx * linear.speed * 5
     location.y.should == y + dy * linear.speed * 5
     location.z.should == z + dz * linear.speed * 5
  end

  it "should rotate location" do
     linear = Motel::MovementStrategies::Linear.new :speed => 5, :step_delay => 5, :dtheta => 0.11, :dphi => 0.22
     dt,dp  = linear.dtheta, linear.dphi

     parent   = Motel::Location.new
     x = y = z = 20
     orientation  = [1,0,0]
     sorientation = Motel::to_spherical(*orientation)
     location = Motel::Location.new(:parent => parent,
                                    :movement_strategy => linear,
                                    :orientation  => orientation,
                                    :x => x, :y => y, :z => z)

     # move and validate
     linear.move location, 1
     location.orientation.should == Motel.from_spherical(sorientation[0] + dt, sorientation[1] + dp, 1)

     orientation  = location.orientation
     sorientation = location.spherical_orientation

     linear.move location, 5
     location.orientation.should == Motel.from_spherical(sorientation[0] + dt * 5, sorientation[1] + dp * 5, 1)
  end

  it "should not move location if strategy is invalid" do
     linear = Motel::MovementStrategies::Linear.new :step_delay => 5, :speed => 20,
                         :direction_vector_x => 5, :direction_vector_y => 5, :direction_vector_z => 5
     parent   = Motel::Location.new
     x = y = z = 20
     location = Motel::Location.new(:parent => parent, :movement_strategy => linear,
                                    :x => x, :y => y, :z => z)

     linear.speed = -10
     linear.valid?.should be_false

     linear.move location, 5
     location.x.should == x
     location.y.should == y
     location.z.should == z
  end

  it "should be convertable to json" do
    m = Motel::MovementStrategies::Linear.new :step_delay => 20,
                                              :speed      => 15,
                                              :dtheta     => 5.14,
                                              :dphi       => 2.22,
                                              :direction_vector_x =>  1,
                                              :direction_vector_y =>  0,
                                              :direction_vector_z =>  0
    j = m.to_json
    j.should include('"json_class":"Motel::MovementStrategies::Linear"')
    j.should include('"step_delay":20')
    j.should include('"speed":15')
    j.should include('"dtheta":5.14')
    j.should include('"dphi":2.22')
    j.should include('"direction_vector_x":1')
    j.should include('"direction_vector_y":0')
    j.should include('"direction_vector_z":0')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Motel::MovementStrategies::Linear","data":{"speed":15,"direction_vector_x":1,"direction_vector_y":0,"step_delay":20,"direction_vector_z":0,"dtheta":5.14,"dphi":2.22}}'
    m = JSON.parse(j)

    m.class.should == Motel::MovementStrategies::Linear
    m.step_delay.should == 20
    m.speed.should == 15
    m.direction_vector_x.should == 1
    m.direction_vector_y.should == 0
    m.direction_vector_z.should == 0
    m.dtheta.should == 5.14
    m.dphi.should == 2.22
  end

end
