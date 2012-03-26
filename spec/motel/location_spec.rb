# location module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Motel::Location do

  it "should successfully accept and set location params" do
     parent = Motel::Location.new
     location = Motel::Location.new :id => 1, :parent_id => 2, :parent => parent, :x => 3, :y => 4, :z => 5
     location.id.should == 1
     location.parent_id.should == 2
     location.x.should == 3
     location.y.should == 4
     location.z.should == 5
     location.parent.should == parent
     location.children.should == []
     location.movement_callbacks.should == []
     location.movement_strategy.should == Motel::MovementStrategies::Stopped.instance

     ms = TestMovementStrategy.new
     location = Motel::Location.new :movement_strategy => ms
     location.movement_strategy.should == ms
  end

  it "should be updatable given another location to copy" do
     p1 = Motel::Location.new
     p2 = Motel::Location.new

     orig = Motel::Location.new :x => 1, :y => 2, :movement_strategy => 'foobar', :parent_id => 5, :parent => p1
     new  = Motel::Location.new :x => 5, :movement_strategy => 'foomoney', :parent_id => 10, :parent => p2
     orig.update(new)
     orig.x.should be(5)
     orig.y.should == 2
     orig.z.should be_nil
     orig.movement_strategy.should == "foomoney"
     orig.parent_id.should be(10)
     orig.parent.should be(p2)

     orig.y = 6
     new.y  = nil
     orig.update(new)
     orig.y.should be(6)
  end

  it "should retrieve a location's coordinates" do
    loc = Motel::Location.new :x => 10, :y => 20, :z => -30
    coords = loc.coordinates
    coords.should == [10, 20, -30]
  end

  it "should retrieve root location" do
    ggp = Motel::Location.new
    gp  = Motel::Location.new :parent => ggp
    p   = Motel::Location.new :parent => gp
    l   = Motel::Location.new :parent => p
    c   = Motel::Location.new :parent => l
    gc  = Motel::Location.new  :parent => c

    gp.root.should == ggp
    p.root.should == ggp
    l.root.should == ggp
    c.root.should == ggp
    gc.root.should == ggp
  end

  it "should provide means to traverse all descendants, invoking optional block arg" do
   greatgrandparent = Motel::Location.new
   grandparent = Motel::Location.new
   greatgrandparent.children.push grandparent
   grampy   = Motel::Location.new
   greatgrandparent.children.push grampy
   parent = Motel::Location.new
   grandparent.children.push parent
   parent2 = Motel::Location.new
   grandparent.children.push parent2
   child1 = Motel::Location.new
   parent.children.push child1
   child2 = Motel::Location.new
   parent.children.push child2

   i = 0 
   greatgrandparent.each_child { |desc|
     i += 1
   }   

   i.should == 6
  end

  it "should return total position from root origin" do
    grandparent = Motel::Location.new
    parent = Motel::Location.new :parent => grandparent,
                          :x      => 14,
                          :y      => 24,
                          :z      => 42 
    child = Motel::Location.new  :parent => parent,
                          :x      => 123,
                          :y      => -846,
                          :z      => -93

    child.total_x.should == 14 + 123
    child.total_y.should == 24 - 846
    child.total_z.should == 42 - 93
  end

  it "should calculate the distance between two locations" do
    loc1 = Motel::Location.new :x => 10, :y => 10, :z => 10
    loc2 = Motel::Location.new :x => -5, :y => -7, :z => 30
    ((loc1 - loc2 - 30.2324329156619) < 0.000001).should be_true
  end

end
