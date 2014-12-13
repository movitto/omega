# Linear Movement Strategy integration tests
#
# Copyright (C) 2009-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/linear'

module Motel::MovementStrategies
describe Linear do
  let(:linear) { Linear.new }
  let(:loc)    { build(:location) }
  let(:parent) { build(:location) }

  it "moves location in direction by speed * elapsed_time" do
    linear.step_delay     = 5
    linear.speed          = 50
    linear.dir            = 0.57, 0.57, 0.57

    loc.parent            = parent
    loc.movement_strategy = linear
    loc.coordinates       = 20, 20, 20
    loc.orientation       = 1, 0, 0

    # move and validate
    intervals = [1, 5, 0.1, 50, 500, 0.001]
    intervals.each { |interval|
      expected = [loc.x + linear.dx * linear.speed * interval,
                  loc.y + linear.dy * linear.speed * interval,
                  loc.z + linear.dz * linear.speed * interval]
      linear.move loc, interval
      loc.x.should be_within(OmegaTest::CLOSE_ENOUGH).of(expected[0])
      loc.y.should be_within(OmegaTest::CLOSE_ENOUGH).of(expected[1])
      loc.z.should be_within(OmegaTest::CLOSE_ENOUGH).of(expected[2])
    }
  end

  it "appends distance moved to loc.distance_moved" do
    linear.step_delay = 5
    linear.speed      = 20
    loc.coordinates   = 0, 0, 0
    loc.orientation   = 1, 0, 0

    linear.move loc, 1
    loc.distance_moved.should == 20
  end

  it "rotates location" do
    linear.speed      = 5
    linear.step_delay = 5
    linear.rot_theta  = 0.11

    loc.coordinates   = 20, 20, 20
    loc.orientation =  1,  0,  0
    loc.parent         = parent
    loc.ms             = linear

    # move and validate
    intervals = [1, 5]
    intervals.each { |interval|
      expected = Motel.rotate(*loc.orientation,
                              linear.rot_theta * interval,
                              *linear.rot_dir)
      linear.move loc, interval
      loc.orientation.should == expected
    }
  end
end # describe Linear
end # module Motel::MovementStrategies
