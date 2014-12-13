# Rotate Movement Strategy integration tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/location'
require 'motel/movement_strategies/rotate'

module Motel::MovementStrategies
describe Rotate do
  let(:rot)    { Rotate.new }
  let(:loc)    { build(:location) }
  let(:parent) { build(:location) }

  it "rotates location" do
    rot.rot_theta   = Math::PI/8
    loc.orientation = 1, 0, 0
    loc.parent      = parent
    loc.ms          = rot

    rt,rx,ry,rz  = rot.rot_theta, rot.rot_x, rot.rot_y, rot.rot_z

    # move and validate
    intervals = [1, 5, 50, 0.1, 0.01]
    intervals.each { |interval|
      expected = Motel.rotate(*loc.orientation, interval * rot.rot_theta,
                              rot.rot_x, rot.rot_y, rot.rot_z)
      rot.move loc, interval
      loc.orientation.should == expected
    }
  end

  it "appends angle rotated to loc.angle_rotated" do
    rot.rot_theta = expected = Math::PI/2
    rot.move loc, 1
    loc.angle_rotated.should be_within(OmegaTest::CLOSE_ENOUGH).of(expected)
  end

  context "stop angle will be exceeded" do
    it "only rotates location up to stop angle" do
      rot.rot_theta  = Math::PI/2
      rot.stop_angle = expected = 1.23
      rot.move loc, 1
      loc.angle_rotated.should == expected
    end
  end
end # describe Rotate
end # Motel::MovementStrategies
