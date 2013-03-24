# location module tests
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Motel::Location do

  it "should successfully accept and set location params" do
     parent = Motel::Location.new
     location = Motel::Location.new :id => 1, :parent_id => 2, :parent => parent,
                                    :x => 3, :y => 4, :z => 5,
                                    :orientation_x => 1,
                                    :orientation_y => 0,
                                    :orientation_z => 0
     location.id.should == 1
     location.parent_id.should == 2
     location.x.should == 3
     location.y.should == 4
     location.z.should == 5
     location.orientation_x.should == 1
     location.orientation_y.should == 0
     location.orientation_z.should == 0
     location.parent.should == parent
     location.children.should == []
     location.movement_callbacks.should == []
     location.proximity_callbacks.should == []
     location.stopped_callbacks.should == []
     location.movement_strategy.should == Motel::MovementStrategies::Stopped.instance

     ms = TestMovementStrategy.new
     location = Motel::Location.new :movement_strategy => ms
     location.movement_strategy.should == ms
  end

  it "should be updatable given another location to copy" do
     p1 = Motel::Location.new
     p2 = Motel::Location.new

     orig = Motel::Location.new :x => 1, :y => 2, :orientation_z => -0.5, :movement_strategy => 'foobar', :parent_id => 5, :parent => p1
     new  = Motel::Location.new :x => 5, :orientation_y => -1, :movement_strategy => 'foomoney', :parent_id => 10, :parent => p2
     orig.update(new)
     orig.x.should == 5
     orig.y.should == 2
     orig.z.should be_nil
     orig.orientation_x.should be_nil
     orig.orientation_y.should == -1
     orig.orientation_z.should == -0.5
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

  it "should retrieve a location's orientation" do
    loc = Motel::Location.new :orientation_x => 50, :orientation_y => -50, :orientation_z => 100
    orientation = loc.orientation
    orientation.should == [50, -50, 100]
  end

  it "should retrieve a location's orientation in spherical coordinates" do
    loc = Motel::Location.new :orientation_x => 1, :orientation_y => 0, :orientation_z => 0
    orientation = loc.spherical_orientation
    orientation.size.should == 2
    (orientation[0] - 1.57).should < 0.001
     orientation[1].should == 0
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

  it "should provide means to traverse all descendants, invoking optional block arg with reference to location" do
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

   parents = []
   children = []
   greatgrandparent.each_child { |lparent, lchild|
     parents << lparent
     children << lchild
   }

   parents.size.should == 6
   parents[0].should == greatgrandparent
   parents[1].should == grandparent
   parents[2].should == parent
   parents[3].should == parent
   parents[4].should == grandparent
   parents[5].should == greatgrandparent

   children.size.should == 6
   children[0].should == grandparent
   children[1].should == parent
   children[2].should == child1
   children[3].should == child2
   children[4].should == parent2
   children[5].should == grampy
  end

  it "should permit adding and removing children" do
    oldparent = Motel::Location.new
    parent    = Motel::Location.new
    child1    = Motel::Location.new :id => 'c1'
    child2    = Motel::Location.new :id => 'c2'

    child1.parent = oldparent

    parent.children.size.should == 0

    parent.add_child(child1)
    parent.children.size.should == 1
    parent.children.include?(child1).should be_true
    child1.parent.should == parent

    parent.add_child(child1)
    parent.children.size.should == 1

    parent.add_child(child2)
    parent.children.size.should == 2
    parent.children.include?(child2).should be_true

    parent.remove_child(child1)
    parent.children.size.should == 1
    parent.children.include?(child1).should be_false
    parent.children.include?(child2).should be_true

    parent.remove_child(child2.id)
    parent.children.should be_empty
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
    ((loc1 - loc2 - 30.2324329156619) < CLOSE_ENOUGH).should be_true
  end

  it "should provide ability to create new location from old plus specified distance" do
    loc1 = Motel::Location.new :x => 4, :y => 2, :z => 0
    loc2 = loc1 + [10, 20, 30]

    loc1.x.should == 4
    loc1.y.should == 2
    loc1.z.should == 0
    loc2.x.should == 14
    loc2.y.should == 22
    loc2.z.should == 30
  end

  it "should be convertable to json" do
    mc1 = Motel::Callbacks::Movement.new :min_distance => 20
    mc2 = Motel::Callbacks::Movement.new :min_y => 30
    pc  = Motel::Callbacks::Proximity.new :max_distance => 50
    sc  = Motel::Callbacks::Stopped.new
    l = Motel::Location.new(:id => 42,
                            :x => 10, :y => -20, :z => 0.5,
                            :orientation => [0, 0, -1],
                            :restrict_view => false, :restrict_modify => true,
                            :parent_id => 15, :remote_queue => 'foobar',
                            :movement_strategy =>
                              Motel::MovementStrategies::Linear.new(:speed => 51))
    l.movement_callbacks  << mc1
    l.movement_callbacks  << mc2
    l.proximity_callbacks << pc
    l.stopped_callbacks   << sc

    j = l.to_json
    j.should include('"json_class":"Motel::Location"')
    j.should include('"id":42')
    j.should include('"x":10')
    j.should include('"y":-20')
    j.should include('"z":0.5')
    j.should include('"orientation_x":0')
    j.should include('"orientation_y":0')
    j.should include('"orientation_z":-1')
    j.should include('"restrict_view":false')
    j.should include('"restrict_modify":true')
    j.should include('"parent_id":15')
    j.should include('"remote_queue":"foobar"')
    j.should include('"movement_strategy":{')
    j.should include('"json_class":"Motel::MovementStrategies::Linear"')
    j.should include('"speed":51')
    j.should include('"movement_callbacks":[')
    j.should include('"json_class":"Motel::Callbacks::Movement"')
    j.should include('"min_distance":20')
    j.should include('"min_y":30')
    j.should include('"proximity_callbacks":[')
    j.should include('"json_class":"Motel::Callbacks::Proximity"')
    j.should include('"max_distance":50')
    j.should include('"stopped_callbacks":[')
    j.should include('"json_class":"Motel::Callbacks::Stopped"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Motel::Location","data":{"y":-20,"restrict_view":false,"parent_id":15,"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Linear","data":{"direction_vector_x":1,"direction_vector_y":0,"direction_vector_z":0,"step_delay":1,"speed":51}},"z":0.5,"remote_queue":"foobar","x":10,"orientation_z":0.5,"id":42}}'
    l = JSON.parse(j)

    l.class.should == Motel::Location
    l.id.should == 42
    l.x.should  == 10
    l.y.should  == -20
    l.z.should  == 0.5
    l.orientation_z.should  == 0.5
    l.restrict_view.should be_false
    l.restrict_modify.should be_true
    l.parent_id.should == 15
    l.remote_queue.should == 'foobar'
    l.movement_strategy.class.should == Motel::MovementStrategies::Linear
    l.movement_strategy.speed.should == 51
  end

  it "should provide means to generate parameterized random location" do
    l = Motel::Location.random :max_x => 10,  :max_y => 20, :max_z => 100,
                               :min_x => 0,   :min_y => 5,  :min_z => 50

    l.x.should < 10
    l.x.should >= -10

    l.y.abs.should < 20
    l.y.abs.should >= 5

    l.z.abs.should < 100
    l.z.abs.should >= 50
  end

end
