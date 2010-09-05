# location module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/spec_helper'

describe Location do

  it "should successfully accept and set location params" do
     parent = Location.new
     location = Location.new :id => 1, :parent_id => 2, :parent => parent, :x => 3, :y => 4, :z => 5
     location.id.should == 1
     location.parent_id.should == 2
     location.x.should == 3
     location.y.should == 4
     location.z.should == 5
     location.parent.should == parent
     location.children.should == []
     location.movement_callbacks.should == []
     location.movement_strategy.should == MovementStrategies::Stopped.instance

     ms = TestMovementStrategy.new
     location = Location.new :movement_strategy => ms
     location.movement_strategy.should == ms
  end

  it "should be updatable given another location to copy" do
     p1 = Location.new
     p2 = Location.new

     orig = Location.new :x => 1, :y => 2, :movement_strategy => 'foobar', :parent_id => 5, :parent => p1
     new  = Location.new :x => 5, :movement_strategy => 'foomoney', :parent_id => 10, :parent => p2
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
    loc = Location.new :x => 10, :y => 20, :z => -30
    coords = loc.coordinates
    coords.should == [10, 20, -30]
  end

  it "should retrieve root location" do
    ggp = Location.new
    gp  = Location.new :parent => ggp
    p   = Location.new :parent => gp
    l   = Location.new :parent => p
    c   = Location.new :parent => l
    gc  = Location.new  :parent => c

    gp.root.should == ggp
    p.root.should == ggp
    l.root.should == ggp
    c.root.should == ggp
    gc.root.should == ggp
  end

  it "should provide means to traverse all descendants, invoking optional block arg" do
   greatgrandparent = Location.new
   grandparent = Location.new
   greatgrandparent.children.push grandparent
   grampy   = Location.new
   greatgrandparent.children.push grampy
   parent = Location.new
   grandparent.children.push parent
   parent2 = Location.new
   grandparent.children.push parent2
   child1 = Location.new
   parent.children.push child1
   child2 = Location.new
   parent.children.push child2

   i = 0 
   greatgrandparent.traverse_descendants { |desc|
     i += 1
   }   

   i.should == 6
  end

  it "should return total position from root origin" do
    grandparent = Location.new
    parent = Location.new :parent => grandparent,
                          :x      => 14,
                          :y      => 24,
                          :z      => 42 
    child = Location.new  :parent => parent,
                          :x      => 123,
                          :y      => -846,
                          :z      => -93

    child.total_x.should == 14 + 123
    child.total_y.should == 24 - 846
    child.total_z.should == 42 - 93
  end

  it "should calculate the distance between two locations" do
    loc1 = Location.new :x => 10, :y => 10, :z => 10
    loc2 = Location.new :x => -5, :y => -7, :z => 30
    ((loc1 - loc2 - 30.2324329156619) < 0.000001).should be_true
  end

end
