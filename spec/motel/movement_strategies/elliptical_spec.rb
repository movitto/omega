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

end
