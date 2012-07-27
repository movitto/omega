# follow movement strategy tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

describe "Motel::MovementStrategies::Follow" do

  it "should successfully accept and set follow params" do
     parent   = Motel::Location.new
     loc1 = Motel::Location.new(:id => 42, :parent => parent, :x => 20, :y => 0, :z => 0)

     Motel::Runner.instance.clear
     Motel::Runner.instance.run loc1

     follow = Motel::MovementStrategies::Follow.new :tracked_location_id => loc1.id, :distance => 20, :speed => 5

     follow.tracked_location_id.should == loc1.id
     follow.distance.should == 20
     follow.speed.should == 5
  end

  it "should return bool indicating validity of movement_strategy" do
     parent   = Motel::Location.new
     loc1 = Motel::Location.new(:id => 1, :parent => parent, :x => 20, :y => 0, :z => 0)

     Motel::Runner.instance.clear
     Motel::Runner.instance.run loc1

     follow = Motel::MovementStrategies::Follow.new :tracked_location_id => loc1.id, :distance => 10, :speed => 5
     follow.valid?.should be_true

     follow.speed = 'foobar'
     follow.valid?.should be_false

     follow.speed = -10
     follow.valid?.should be_false
     follow.speed = 5

     follow.distance = 'foobar'
     follow.valid?.should be_false

     follow.distance = -10
     follow.valid?.should be_false
     follow.distance = 10

     follow.tracked_location_id = nil
     follow.valid?.should be_false

     follow.tracked_location_id = loc1.id
     follow.valid?.should be_true
  end

  it "should move location correctly" do
     parent   = Motel::Location.new
     loc1 = Motel::Location.new(:id => 1, :parent => parent, :x => 20, :y => 0, :z => 0)
     loc2 = Motel::Location.new(:id => 2, :parent => parent, :x => 0,  :y => 0, :z => 0)

     Motel::Runner.instance.clear
     Motel::Runner.instance.run loc1
     Motel::Runner.instance.run loc2

     follow = Motel::MovementStrategies::Follow.new :tracked_location_id => loc2.id, :distance => 10, :speed => 5

     # move and validate
     follow.move loc1, 1
     loc1.x.should == 15

     follow.move loc1, 1
     loc1.x.should == 10
 
     follow.move loc1, 1
     loc1.x.should == 10
  end

  it "should not move location if strategy is invalid or does not refer to location in registry" do
     parent   = Motel::Location.new :id => 15
     loc1 = Motel::Location.new(:id => 1, :parent => parent, :x => 20, :y => 0, :z => 0)
     loc2 = Motel::Location.new(:id => 2, :parent => parent, :x => 0,  :y => 0, :z => 0)

     Motel::Runner.instance.clear
     Motel::Runner.instance.run loc1
     Motel::Runner.instance.run loc2

     follow = Motel::MovementStrategies::Follow.new :tracked_location_id => loc2.id, :distance => 10, :speed => 5

     follow.distance = -10
     follow.valid?.should be_false

     follow.move loc1, 5
     loc1.x.should == 20
     loc1.y.should == 0
     loc1.z.should == 0

     follow.distance = 10
     follow.valid?.should be_true

     follow.tracked_location_id = 420
     follow.move loc1, 5
     loc1.x.should == 20
     loc1.y.should == 0
     loc1.z.should == 0
     follow.tracked_location_id = loc2.id

     # should raise error if parent locations are different
     loc1.parent_id = 50
     follow.move loc1, 5
     loc1.x.should == 20
     loc1.y.should == 0
     loc1.z.should == 0
  end

  it "should be convertable to json" do
    m = Motel::MovementStrategies::Follow.new :step_delay => 20,
                                              :speed      => 15,
                                              :tracked_location_id =>  1,
                                              :distance =>  22
    j = m.to_json
    j.should include('"json_class":"Motel::MovementStrategies::Follow"')
    j.should include('"step_delay":20')
    j.should include('"speed":15')
    j.should include('"tracked_location_id":1')
    j.should include('"distance":22')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Motel::MovementStrategies::Follow","data":{"speed":15,"tracked_location_id":1,"distance":22,"step_delay":20}}'
    m = JSON.parse(j)

    m.class.should == Motel::MovementStrategies::Follow
    m.step_delay.should == 20
    m.speed.should == 15
    m.tracked_location_id.should == 1
    m.distance.should == 22
  end

end
