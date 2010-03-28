# runner module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/spec_helper'

describe Runner do

  it "manage array of locations to be run" do
    loc = Location.new :id => 50
    Runner.instance.clear
    Runner.instance.locations.should == []
    Runner.instance.run loc
    Runner.instance.locations.should == [loc]
    Runner.instance.clear
  end

  it "should run managed locations" do
    loc1 = Location.new :id => 100, :movement_strategy => TestMovementStrategy.new
    loc2 = Location.new :id => 200, :movement_strategy => TestMovementStrategy.new
    Runner.instance.clear
    Runner.instance.run loc1
    Runner.instance.run loc2
    Runner.instance.locations.size.should == 2

    Runner.instance.start :async => true, :num_threads => 10
    #Runner.instance.thread_pool.should_not == nil
    #Runner.instance.thread_pool.max_size.should == 10
    Runner.instance.terminate.should == false

    # sleep here to allow move to be called
    sleep 2

    Runner.instance.stop
    Runner.instance.terminate.should == true

    Runner.instance.join
    Runner.instance.run_thread.should == nil

    loc1.movement_strategy.times_moved.should be > 0
    loc2.movement_strategy.times_moved.should be > 0
  end

end
