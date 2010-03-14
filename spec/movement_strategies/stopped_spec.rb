# stopped movement strategy tests
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require File.dirname(__FILE__) + '/../spec_helper'

describe "Motel::MovementStrategies::Stopped" do

  it "should not move location" do
     # setup test
     stopped = Stopped.instance
     parent   = Location.new
     x = 50
     y = 100 
     z = 200 
     location = Location.new(:parent => parent,
                             :movement_strategy => stopped,
                             :x => 50, :y => 100, :z => 200)

     # make sure location does not move
     stopped.move location, 10
     location.x.should == x
     location.y.should == y
     location.z.should == z

     stopped.move location, 50
     location.x.should == x
     location.y.should == y
     location.z.should == z

     stopped.move location, 0
     location.x.should == x
     location.y.should == y
     location.z.should == z

  end

end
