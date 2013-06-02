# stopped movement strategy tests
#
# Copyright (C) 2009-2013 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/stopped'

module Motel::MovementStrategies
describe Stopped do
  describe "#valid?" do
    it "returns true" do
      Stopped.instance.should be_valid
    end
  end

  describe "#move" do
    it "does nothing" do
      stopped = Stopped.instance
      l = build(:location)
      x,y,z = l.coordinates
                              
      # make sure location does not move
      stopped.move l, 10
      l.x.should == x
      l.y.should == y
      l.z.should == z

      stopped.move l, 50
      l.x.should == x
      l.y.should == y
      l.z.should == z

      stopped.move l, 0
      l.x.should == x
      l.y.should == y
      l.z.should == z
    end
  end

  describe "#json_create" do
    it "returns singleton instnace" do
      j  = '{"json_class":"Motel::MovementStrategies::Stopped","data":{}}'
      ms = JSON.parse j
      ms.should == Motel::MovementStrategies::Stopped.instance
    end
  end

end # describe Stopped
end # module Motel::MovementStrategies
