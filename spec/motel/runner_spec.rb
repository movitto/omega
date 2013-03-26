# runner module tests
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'stringio'

describe Motel::Runner do
  before(:each) do
    @loc1 = Motel::Location.new :id => 1, :x => 1, :y => 1, :z => 1,
                                :movement_strategy => TestMovementStrategy.new
    @loc2 = Motel::Location.new :id => 2, :x => 2, :y => 2, :z => 2,
                                :movement_strategy => TestMovementStrategy.new
    @loc3 = Motel::Location.new :id => 3, :x => 3, :y => 3, :z => 3,
                                :movement_strategy => TestMovementStrategy.new

    @loc050 = Motel::Location.new :id => 050, :x =>  50, :y =>  50, :z =>  50
    @loc100 = Motel::Location.new :id => 2100, :x => 100, :y => 100, :z => 100,
                                  :movement_strategy => TestMovementStrategy.new
    @loc200 = Motel::Location.new :id => 2200, :x => 200, :y => 200, :z => 200,
                                  :movement_strategy => TestMovementStrategy.new
  end

  it "manage array of locations to be run" do
    Motel::Runner.instance.clear
    Motel::Runner.instance.locations.should == []
    Motel::Runner.instance.run @loc050
    Motel::Runner.instance.locations.should == [@loc050]
  end

  it "should run managed locations" do
    old = Motel::Runner.instance.locations.size
    Motel::Runner.instance.run @loc100
    Motel::Runner.instance.run @loc200
    Motel::Runner.instance.locations.size.should == old + 2

    # TODO ensure movement + rotation + proximity callbacks are invoked

    Motel::Runner.instance.start
    #Motel::Runner.instance.thread_pool.should_not == nil
    #Motel::Runner.instance.thread_pool.max_size.should == 10
    Motel::Runner.instance.instance_variable_get(:@terminate).should == false

    # sleep here to allow move to be called
    sleep 2

    Motel::Runner.instance.stop
    Motel::Runner.instance.instance_variable_get(:@terminate).should == true

    Motel::Runner.instance.join
    #Motel::Runner.instance.run_thread.should == nil

    @loc100.movement_strategy.times_moved.should be > 0
    @loc200.movement_strategy.times_moved.should be > 0
  end

  it "should set id on managed location to be run if missing" do
    old = Motel::Runner.instance.locations.size
    Motel::Runner.instance.run @loc100
    Motel::Runner.instance.run @loc200
    Motel::Runner.instance.locations.size.should == old + 2

    loc2a = Motel::Runner.instance.run @loc2
    loc2a.id.should == 2
    Motel::Runner.instance.locations.size.should == old + 3
  end

  it "should save running locations to io object" do
    old = Motel::Runner.instance.locations.size
    Motel::Runner.instance.run @loc1
    Motel::Runner.instance.run @loc2
    Motel::Runner.instance.locations.size.should == old + 2

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
    a = s.split "\n"

    Motel::Runner.instance.clear
    Motel::Runner.instance.restore_state(a)
    Motel::Runner.instance.locations.size.should == 2

    ids = Motel::Runner.instance.locations.collect { |l| l.id }
    ids.should include(1)
    ids.should include(3)
  end

end
