# stopped movement strategy tests
#
# Copyright (C) 2009-2013 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/stopped'

module Motel::MovementStrategies
describe Stopped do
  let(:stopped) { Stopped.instance }
  let(:loc)     { build(:location) }

  describe "#valid?" do
    it "returns true" do
      stopped.should be_valid
    end
  end

  describe "#move" do
    it "does nothing" do
      coords = loc.coordinates

      # make sure location does not move
      intervals = [0, 10, 50]
      intervals.each { |interval|
        stopped.move loc, interval
        loc.coordinates.should == coords
      }
    end
  end

  describe "#json_create" do
    it "returns singleton instnace" do
      j  = '{"json_class":"Motel::MovementStrategies::Stopped","data":{}}'
      ms = RJR::JSONParser.parse j
      ms.should == Motel::MovementStrategies::Stopped.instance
    end
  end
end # describe Stopped
end # module Motel::MovementStrategies
