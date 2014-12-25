# Elliptical Movement Strategy integration tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/elliptical'

module Motel::MovementStrategies
describe Elliptical, :integration => true do
  it "moves location along elliptical path by speed * elapsed_time" do
    e = Elliptical.new(:step_delay        => 5,
                       :relative_to       => Elliptical::CENTER,
                       :speed             => 1.57,
                       :e => 0, # circle
                       :p => 1,
                       :direction => [1,0,0,0,1,0])

    x,y,z = 1,0,0
    l = Motel::Location.new(:movement_strategy => e,
                            :x => x, :y => y, :z => z)

    # move and validate
    e.move l, 1
    (0 - l.x).abs.round_to(2).should == 0
    (1 - l.y).abs.round_to(2).should == 0
    (0 - l.z).abs.round_to(2).should == 0

    e.move l, 1
    (-1 - l.x).abs.round_to(2).should == 0
    (0  - l.y).abs.round_to(2).should == 0
    (0  - l.z).abs.round_to(2).should == 0

    e.move l, 1
    (0  - l.x).abs.round_to(2).should == 0
    (-1 - l.y).abs.round_to(2).should == 0
    (0  - l.z).abs.round_to(2).should == 0

    e.move l, 1
    (1  - l.x).abs.round_to(2).should == 0
    (0 - l.y).abs.round_to(2).should == 0
    (0  - l.z).abs.round_to(2).should == 0
  end
end # describe Elliptical
end # module Motel::MovementStrategies
