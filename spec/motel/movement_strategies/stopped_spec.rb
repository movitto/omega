# stopped movement strategy tests
#
# Copyright (C) 2009-2012 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

describe "Motel::MovementStrategies::Stopped" do

  it "should not move location" do
     # setup test
     stopped = Motel::MovementStrategies::Stopped.instance
     parent   = Motel::Location.new
     x = 50
     y = 100 
     z = 200 
     location = Motel::Location.new(:parent => parent,
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
