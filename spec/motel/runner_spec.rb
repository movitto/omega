# runner module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

require 'stringio'

describe Motel::Runner do

  it "manage array of locations to be run" do
    loc = Motel::Location.new :id => 50
    Motel::Runner.instance.clear
    Motel::Runner.instance.locations.should == []
    Motel::Runner.instance.run loc
    Motel::Runner.instance.locations.should == [loc]
    Motel::Runner.instance.clear
  end

  it "should run managed locations" do
    loc1 = Motel::Location.new :id => 100, :movement_strategy => TestMovementStrategy.new
    loc2 = Motel::Location.new :id => 200, :movement_strategy => TestMovementStrategy.new
    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1
    Motel::Runner.instance.run loc2
    Motel::Runner.instance.locations.size.should == 2

    # TODO ensure movement + proximity callbacks are invoked

    Motel::Runner.instance.start :async => true, :num_threads => 10
    #Motel::Runner.instance.thread_pool.should_not == nil
    #Motel::Runner.instance.thread_pool.max_size.should == 10
    Motel::Runner.instance.terminate.should == false

    # sleep here to allow move to be called
    sleep 2

    Motel::Runner.instance.stop
    Motel::Runner.instance.terminate.should == true

    Motel::Runner.instance.join
    Motel::Runner.instance.run_thread.should == nil

    loc1.movement_strategy.times_moved.should be > 0
    loc2.movement_strategy.times_moved.should be > 0
  end

  it "should set id on managed location to be run if missing" do
    loc1 = Motel::Location.new :id => 1, :movement_strategy => TestMovementStrategy.new
    loc3 = Motel::Location.new :id => 3, :movement_strategy => TestMovementStrategy.new
    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1
    Motel::Runner.instance.run loc3
    Motel::Runner.instance.locations.size.should == 2

    loc2 = Motel::Location.new :movement_strategy => TestMovementStrategy.new
    loc2a = Motel::Runner.instance.run loc2
    loc2.id.should == 2
    Motel::Runner.instance.locations.size.should == 3
  end

  it "should save running locations to io object" do
    loc1 = Motel::Location.new :id => 1, :movement_strategy => TestMovementStrategy.new
    loc3 = Motel::Location.new :id => 3, :movement_strategy => TestMovementStrategy.new
    Motel::Runner.instance.clear
    Motel::Runner.instance.run loc1
    Motel::Runner.instance.run loc3
    Motel::Runner.instance.locations.size.should == 2

    sio = StringIO.new
    Motel::Runner.instance.save_state(sio)
    s = sio.string

    s.should include('"id":1')
    s.should include('"id":3')
    s.should include('"json_class":"TestMovementStrategy"')
    s.should include('"json_class":"Motel::Location"')
  end

  it "should restore running locations from io object" do
    s = '{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"TestMovementStrategy"},"remote_queue":null,"parent_id":null,"y":null,"z":null,"x":null,"restrict_view":true,"id":1,"restrict_modify":true},"json_class":"Motel::Location"}' + "\n" +
        '{"data":{"movement_strategy":{"data":{"step_delay":1},"json_class":"TestMovementStrategy"},"remote_queue":null,"parent_id":null,"y":null,"z":null,"x":null,"restrict_view":true,"id":3,"restrict_modify":true},"json_class":"Motel::Location"}'
    a = s.collect { |i| i }

    Motel::Runner.instance.clear
    Motel::Runner.instance.restore_state(a)
    Motel::Runner.instance.locations.size.should == 2

    ids = Motel::Runner.instance.locations.collect { |l| l.id }
    ids.should include(1)
    ids.should include(3)
  end

end
