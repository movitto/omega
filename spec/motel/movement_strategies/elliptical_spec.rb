# elliptical movement strategy tests
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require File.dirname(__FILE__) + '/../../spec_helper'

Elliptical = Motel::MovementStrategies::Elliptical

describe "Motel::MovementStrategies::Elliptical" do

  it "should successfully accept and set elliptical params" do
     elliptical = Elliptical.new :relative_to => Elliptical::RELATIVE_TO_CENTER, :speed => 5,
                                 :eccentricity => 0.5, :semi_latus_rectum => 10,
                                 :direction_major_x => 1, :direction_major_y => 3,  :direction_major_z => 2,
                                 :direction_minor_x => 3, :direction_minor_y => -1, :direction_minor_z => 0
                                 
     # the orthogonal direction vectors get normalized                                  
     (elliptical.direction_major_x - 0.267261241912424).abs.should < CLOSE_ENOUGH
     (elliptical.direction_major_y - 0.801783725737273).abs.should < CLOSE_ENOUGH
     (elliptical.direction_major_z - 0.534522483824849).abs.should < CLOSE_ENOUGH
     (elliptical.direction_minor_x - 0.948683298050514).abs.should < CLOSE_ENOUGH
     (elliptical.direction_minor_y - -0.316227766016838).abs.should < CLOSE_ENOUGH
     elliptical.direction_minor_z.should == 0

     elliptical.speed.should == 5
     elliptical.relative_to.should == Elliptical::RELATIVE_TO_CENTER
     elliptical.eccentricity.should == 0.5
     elliptical.semi_latus_rectum.should == 10
  end

  it "should successfully accept and set direction vectors in combined form" do
    elliptical = Elliptical.new :direction => [[1,0,0],[0,1,0]]
    elliptical.direction_major_x.should == 1
    elliptical.direction_major_y.should == 0
    elliptical.direction_major_z.should == 0
    elliptical.direction_minor_x.should == 0
    elliptical.direction_minor_y.should == 1
    elliptical.direction_minor_z.should == 0

    elliptical = Elliptical.new :direction_major => [0,0,1],
                                :direction_minor => [0,1,0]
    elliptical.direction_major_x.should == 0
    elliptical.direction_major_y.should == 0
    elliptical.direction_major_z.should == 1
    elliptical.direction_minor_x.should == 0
    elliptical.direction_minor_y.should == 1
    elliptical.direction_minor_z.should == 0

    elliptical = Elliptical.new :direction => [[1,0,0],[0,1,0]],
                                :direction_major => [0,1,0],
                                :direction_minor_x => 1,
                                :direction_minor_y => 0
    elliptical.direction_major_x.should == 0
    elliptical.direction_major_y.should == 1
    elliptical.direction_major_z.should == 0
    elliptical.direction_minor_x.should == 1
    elliptical.direction_minor_y.should == 0
    elliptical.direction_minor_z.should == 0
  end

  it "should default to standard cartesian direction axis" do
     elliptical = Elliptical.new
     elliptical.direction_major_x.should == 1
     elliptical.direction_major_y.should == 0
     elliptical.direction_major_z.should == 0
     elliptical.direction_minor_x.should == 0
     elliptical.direction_minor_y.should == 1
     elliptical.direction_minor_z.should == 0
  end

  it "should raise exception if direction vectors are orthogonal" do
     lambda { 
       elliptical = Elliptical.new :direction_major_x => 0.75, :direction_major_y => -0.33,  :direction_major_z => -0.21,
                                   :direction_minor_x => -0.41, :direction_minor_y => 0, :direction_minor_z => 0.64
     }.should raise_error(Motel::InvalidMovementStrategy, "elliptical direction vectors not orthogonal")
  end


  it "should move location correctly" do
     elliptical = Elliptical.new(:step_delay        => 5,
                                 :relative_to       => Elliptical::RELATIVE_TO_CENTER,
                                 :speed             => 1.57,
                                 :eccentricity      => 0, # circle
                                 :semi_latus_rectum => 1,
                                 :direction_major_x => 1,
                                 :direction_major_y => 0,
                                 :direction_major_z => 0,
                                 :direction_minor_x => 0,
                                 :direction_minor_y => 1,
                                 :direction_minor_z => 0)

     parent   = Motel::Location.new
     x = 1
     y = z = 0
     location = Motel::Location.new(:parent => parent,
                             :movement_strategy => elliptical,
                             :x => x, :y => y, :z => z)

     # move and validate
     elliptical.move location, 1
     (0 - location.x).abs.round_to(2).should == 0
     (1 - location.y).abs.round_to(2).should == 0
     (0 - location.z).abs.round_to(2).should == 0

     elliptical.move location, 1
     (-1 - location.x).abs.round_to(2).should == 0
     (0  - location.y).abs.round_to(2).should == 0
     (0  - location.z).abs.round_to(2).should == 0

     elliptical.move location, 1
     (0  - location.x).abs.round_to(2).should == 0
     (-1 - location.y).abs.round_to(2).should == 0
     (0  - location.z).abs.round_to(2).should == 0

     elliptical.move location, 1
     (1  - location.x).abs.round_to(2).should == 0
     (0 - location.y).abs.round_to(2).should == 0
     (0  - location.z).abs.round_to(2).should == 0
  end

  # TODO test other orbital methods

  it "should be convertable to json" do
   m = Motel::MovementStrategies::Elliptical.new :relative_to => Motel::MovementStrategies::Elliptical::RELATIVE_TO_CENTER,
                                                 :step_delay        => 21,
                                                 :speed             => 42,
                                                 :eccentricity      => 0.5,
                                                 :semi_latus_rectum => 420,
                                                 :direction_major_x => 1,
                                                 :direction_major_y => 0,
                                                 :direction_major_z => 0,
                                                 :direction_minor_x => 0,
                                                 :direction_minor_y => 1,
                                                 :direction_minor_z => 0
    j = m.to_json
    j.should include('"json_class":"Motel::MovementStrategies::Elliptical"')
    j.should include('"step_delay":21')
    j.should include('"speed":42')
    j.should include('"relative_to":"center"')
    j.should include('"eccentricity":0.5')
    j.should include('"semi_latus_rectum":420')
    j.should include('"direction_major_x":1')
    j.should include('"direction_major_y":0')
    j.should include('"direction_major_z":0')
    j.should include('"direction_minor_x":0')
    j.should include('"direction_minor_y":1')
    j.should include('"direction_minor_z":0')
    j.should include('"orbit":['+m.orbit.collect{ |o| '['+o.join(',')+']' }.join(',')+']')
  end

  it "should be convertable from json" do
    j = '{"data":{"direction_major_y":0,"speed":42,"direction_major_z":0,"relative_to":"center","direction_minor_x":0,"eccentricity":0.5,"direction_minor_y":1,"semi_latus_rectum":420,"step_delay":21,"direction_minor_z":0,"direction_major_x":1},"json_class":"Motel::MovementStrategies::Elliptical"}'
    m = JSON.parse(j)

    m.class.should == Motel::MovementStrategies::Elliptical
    m.step_delay.should == 21
    m.speed.should == 42
    m.relative_to.should == "center"
    m.eccentricity.should == 0.5
    m.semi_latus_rectum.should == 420
    m.direction_major_x.should == 1
    m.direction_major_y.should == 0
    m.direction_major_z.should == 0
    m.direction_minor_x.should == 0
    m.direction_minor_y.should == 1
    m.direction_minor_z.should == 0
  end

  it "should permit generating parameterized random elliptical movement strategy" do
    m = Motel::MovementStrategies::Elliptical.random :dimensions => 2,
                                                     :relative_to => "foci",
                                                     :min_e      => 0.3,
                                                     :max_e      => 0.7,
                                                     :min_l      => 90,
                                                     :max_l      => 120,
                                                     :min_s      => 10,
                                                     :max_s      => 20
    m.direction_major_z.should == 0
    m.direction_minor_z.should == 0

    m.relative_to.should == "foci"

    m.e.should >= 0.3
    m.e.should < 0.7

    m.p.should >= 90
    m.p.should < 120

    m.speed.should >= 10
    m.speed.should < 20
  end


end
