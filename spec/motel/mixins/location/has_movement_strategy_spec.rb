# Location HasMovementStrategy Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  let(:loc)     { build(:location) }
  let(:other)   { build(:location) }
  let(:linear)  { Motel::MovementStrategies::Linear.new }
  let(:stopped) { Motel::MovementStrategies::Stopped.instance }

  describe "#movement_strategy_from_args" do
    it "initializes movement strategy" do
      loc.movement_strategy_from_args :movement_strategy => linear
      loc.movement_strategy.should == linear
    end

    it "initializes next movement strategy" do
      loc.movement_strategy_from_args :next_movement_strategy => linear
      loc.next_movement_strategy.should == linear
    end


    it "defaults to stopped movement strategy" do
      loc.movement_strategy_from_args({})
      loc.movement_strategy.should == stopped
    end

    it "defaults to nil next movement strategy" do
      loc.movement_strategy_from_args({})
      loc.next_movement_strategy.should be_nil
    end
  end

  describe "#stopped?" do
    context "movement strategy is Stopped instance" do
      it "returns true" do
        loc.movement_strategy = stopped
        loc.should be_stopped
      end
    end

    context "movement strategy is not Stopped instance" do
      it "returns false" do
        loc.movement_strategy = linear
        loc.should_not be_stopped
      end
    end
  end

  describe "#movement_strategy_valid?" do
    context "movement_strategy is not a MovementStrategy" do
      it "returns false" do
        loc.ms = :foo
        loc.movement_strategy_valid?.should be_false
      end
    end

    context "movement strategy is not valid" do
      it "returns false" do
        loc.ms = linear
        loc.ms.should_receive(:valid?).and_return(false)
        loc.movement_strategy_valid?.should be_false
      end
    end

    it "returns true" do
      loc.ms = linear
      loc.ms.should_receive(:valid?).and_return(true)
      loc.movement_strategy_valid?.should be_true
    end
  end

  describe "#movement_strategy_json" do
    it "returns movement strategy json data hash" do
      loc.movement_strategy_json.should be_an_instance_of(Hash)
    end

    it "returns movement strategy in json data hash" do
      loc.ms = linear
      loc.movement_strategy_json[:movement_strategy].should == linear
    end

    it "returns next movement strategy in json data hash" do
      loc.next_movement_strategy = linear
      loc.movement_strategy_json[:next_movement_strategy].should == linear
    end
  end

  describe "#should_move?" do
    context "last_moved is nil" do
      it "returns true" do
        loc.last_moved_at = nil
        loc.should_move?.should be_true
      end
    end

    context "time_since_movement > movement_strategy.step_delay" do
      it "returns true" do
        loc.last_moved_at = Time.now - 20
        linear.step_delay = 10
        loc.movement_strategy = linear
        loc.should_move?.should be_true
      end
    end

    context "last moved is set and time_since_movement < step_delay" do
      it "returns false" do
        loc.last_moved_at = Time.now
        linear.step_delay = 20
        loc.movement_strategy = linear
        loc.should_receive(:time_since_movement).and_return(10)
        loc.should_move?.should be_false
      end
    end
  end

  describe "#time_util_movement" do
    context "step_delay > time_since_movement" do
      it "returns delay - time_since_movement" do
        linear.step_delay = 20
        loc.movement_strategy = linear
        loc.should_receive(:time_since_movement).and_return(10)
        loc.time_until_movement.should == 10
      end
    end

    context "time_since_movement is nil" do
      it "returns 0" do
        linear.step_delay = 0.1
        loc.movement_strategy = linear
        loc.should_receive(:time_since_movement).and_return(nil)
        loc.time_until_movement.should == 0
      end
    end

    context "step_delay < time_since_movement" do
      it "returns 0" do
        linear.step_delay = 10
        loc.movement_strategy = linear
        loc.should_receive(:time_since_movement).and_return(20)
        loc.time_until_movement.should == 0
      end
    end
  end

  describe "#movement_strategy_eql?" do
    context "movement_strategy == other.movement_strategy" do
      it "returns true" do
        loc.ms = other.ms = stopped
        loc.movement_strategy_eql?(other).should be_true
      end
    end

    context "movement_strategy != other.movement_strategy" do
      it "returns false" do
        loc.ms = linear
        other.ms = stopped
        loc.movement_strategy_eql?(other).should be_false
      end
    end
  end
end # describe Location
end # module Motel
