# linear movement strategy tests
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require File.dirname(__FILE__) + '/../spec_helper'

describe "Motel::MovementStrategies::Linear" do

  it "should successfully accept and set linear params" do
     linear = Linear.new :direction_vector_x => 1, :direction_vector_y => 2, :direction_vector_z => 3, :speed => 5

     # ensure linear vector gets automatically normailized
     dx,dy,dz = normalize 1,2,3
     linear.direction_vector_x.should == dx
     linear.direction_vector_y.should == dy
     linear.direction_vector_z.should == dz

     linear.speed.should == 5
  end


  it "should move location correctly" do
     linear = Linear.new :step_delay => 5, :speed => 20, 
                         :direction_vector_x => 5, :direction_vector_y => 5, :direction_vector_z => 5
     dx,dy,dz = linear.direction_vector_x, linear.direction_vector_y, linear.direction_vector_z

     parent   = Location.new
     x = y = z = 20
     location = Location.new(:parent => parent,
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

end
