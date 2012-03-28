# linear movement strategy tests
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require File.dirname(__FILE__) + '/../../spec_helper'

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

  it "should be convertable to json" do
    m = Motel::MovementStrategies::Linear.new :step_delay => 20,
                                              :speed      => 15,
                                              :direction_vector_x =>  1,
                                              :direction_vector_y =>  0,
                                              :direction_vector_z =>  0
    j = m.to_json
    j.should include('"json_class":"Motel::MovementStrategies::Linear"')
    j.should include('"step_delay":20')
    j.should include('"speed":15')
    j.should include('"direction_vector_x":1')
    j.should include('"direction_vector_y":0')
    j.should include('"direction_vector_z":0')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Motel::MovementStrategies::Linear","data":{"speed":15,"direction_vector_x":1,"direction_vector_y":0,"step_delay":20,"direction_vector_z":0}}'
    m = JSON.parse(j)

    m.class.should == Motel::MovementStrategies::Linear
    m.step_delay.should == 20
    m.speed.should == 15
    m.direction_vector_x.should == 1
    m.direction_vector_y.should == 0
    m.direction_vector_z.should == 0
  end

end
