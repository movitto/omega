# movement strategy module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/spec_helper'

describe MovementStrategy do

  it "should successfully accept and set movement strategy params" do
     ms = MovementStrategy.new :step_delay => 10
     ms.step_delay.should == 10
  end

  it "should default to no movement" do
     loc = Location.new :x => 100, :y => -200, :z => 300
     ms = MovementStrategy.new
     ms.move loc, 2000
     loc.x.should == 100
     loc.y.should == -200
     loc.z.should == 300
  end

end
