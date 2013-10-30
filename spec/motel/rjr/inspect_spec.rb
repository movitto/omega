# motel::status test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/inspect'
require 'rjr/dispatcher'

module Motel::RJR
  describe "#status", :rjr => true do
    before(:each) do
      dispatch_to @s, Motel::RJR, :INSPECT_METHODS
    end

    it "returns registry.running?" do
      Motel::RJR.registry.should_receive(:running?).and_return(:foo)
      @s.get_status[:running].should == :foo
    end

    it "returns registry.entities.size" do
      Motel::RJR.registry << build(:location)
      Motel::RJR.registry << build(:location)
      @s.get_status[:num_locations].should == 2
    end

    it "returns map of movement strategies to number of locations with them" do
      l1 = build(:location, :movement_strategy =>
             Motel::MovementStrategies::Linear.new(:speed => 5))
      l2 = build(:location)
      l3 = build(:location)

      Motel::RJR.registry << l1
      Motel::RJR.registry << l2
      Motel::RJR.registry << l3
      @s.get_status[:movement_strategies][Motel::MovementStrategies::Stopped].should == 2
      @s.get_status[:movement_strategies][Motel::MovementStrategies::Linear].should == 1
      @s.get_status[:movement_strategies][Motel::MovementStrategies::Elliptical].should == 0
    end
  end # describe "#status"

  describe "#dispatch_motel_rjr_inspect" do
    it "adds motel::status to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_motel_rjr_inspect(d)
      d.handlers.keys.should include("motel::status")
    end
  end

end #module Users::RJR
