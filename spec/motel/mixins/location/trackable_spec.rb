# Location Trackable Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  describe "#reset_tracked_attributes" do
    it "should reset distance moved" do
      l = Location.new
      l.distance_moved = 50
      l.reset_tracked_attributes
      l.distance_moved.should == 0
    end

    it "should reset angle rotated" do
      l = Location.new
      l.angle_rotated = 3.14
      l.reset_tracked_attributes
      l.angle_rotated.should == 0
    end
  end
end # describe Location
end # module Motel
