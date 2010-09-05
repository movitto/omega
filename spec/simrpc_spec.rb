# simrpc module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

dir = File.dirname(__FILE__)
require dir + '/spec_helper'

describe "Motel::Simrpc" do

  before(:each) do
    # setup simrpc endpoints
    @server = Motel::Server.new :schema_file => dir + '/../conf/motel-schema.xml'
    @client = Motel::Client.new :schema_file => dir + '/../conf/motel-schema.xml'
  end

  it "should fail to retreive invalid location" do
    @client.get_location(-500).should be_nil
  end

  it "should permit location creation and retrieval" do
    locations = Runner.instance.locations.size
    clocation = Location.new :id => 10, :x => 100, :y => -200, :z => 500
    tloc = @client.create_location(clocation)
    tloc.id.should == clocation.id
    tloc.x.should == 100
    tloc.y.should == -200
    tloc.z.should == 500
    Runner.instance.locations.size.should == locations + 1

    # FIXME test setting / retrieving movement strategy

    loc = @client.get_location(clocation.id)
    loc.should_not be_nil
    loc.id.should be(clocation.id)
    loc.x.should == 100
    loc.y.should == -200
    loc.z.should == 500
  end

  it "should autogenerate location id and coordinates on creation if not specified" do
    Runner.instance.clear
    loc1 = Location.new :id => 1
    loc2 = Location.new :id => 2
    loc4 = Location.new :id => 4
    @client.create_location(loc1)
    @client.create_location(loc2)
    @client.create_location(loc4)

    loc3 = @client.create_location(Location.new)
    loc3.id.should == 3
    loc3.x.should == 0
    loc3.y.should == 0
    loc3.z.should == 0

    Runner.instance.locations.size.should == 4

    loc3a = @client.get_location(3)
    loc3a.should_not be_nil
  end

  it "should autogenerate location if none is specified on creation" do
    Runner.instance.clear
    loc = @client.create_location
    loc.id.should == 1
    loc.x.should == 0
    loc.y.should == 0
    loc.z.should == 0

    Runner.instance.locations.size.should == 1

    loc = @client.get_location(1)
    loc.should_not be_nil
  end

  it "should permit updating a location" do
    clocation = Location.new :id => 20
    @client.create_location(clocation).id.should == clocation.id
    @client.update_location(Location.new(:id => clocation.id, :x => 150, :y => 300, :z => -600)).should be(true)

    loc = @client.get_location(clocation.id)
    loc.should_not be_nil
    loc.x.should be(150)
    loc.y.should be(300)
    loc.z.should be(-600)

    loc = @client.request :get_location, clocation.id
    loc.should_not be_nil
    loc.x.should be(150)
  end

  #it "should invoke callbacks when updating a location" do
  #  Runner.instance.clear
  #  clocation = Location.new :id => 250
  #  @client.create_location(clocation).id.should == clocation.id

  #  # handle and subscribe to location movement
  #  times_moved = 0
  #  @client.on_location_moved = lambda { |location, d, dx, dy, dz|
  #    times_moved += 1
  #  }
  #  @client.subscribe_to_location_movement(clocation.id).should be(true)

  #  res = @client.update_location(Location.new(:id => clocation.id, :x => 150, :y => 300, :z => -600))
  #  res.should be(true)

  #  loc = @client.get_location(clocation.id)
  #  loc.should_not be_nil
  #  loc.x.should be(150)
  #  loc.y.should be(300)
  #  loc.z.should be(-600)
  #  times_moved.should be(1)
  #end

  it "should permit receiving location movement updates" do
    # start the runner here, to actual move location / process callbacks
    Runner.instance.clear
    Runner.instance.start :async => true

    # create the location
    clocation = Location.new :id => 30
    @client.create_location(clocation).id.should == clocation.id

    ## set a linear movement strategy
    location = Location.new
    location.id = clocation.id
    location.movement_strategy = Linear.new(:step_delay => 1,
                                            :speed      => 15,
                                            :direction_vector_x => 1,
                                            :direction_vector_y => 0,
                                            :direction_vector_z => 0)
    @client.update_location(location).should be(true)

    times_moved = 0

    # handle location_moved method
    @client.on_location_moved = lambda { |location, d, dx, dy, dz|
      times_moved += 1
    }

    ## subscribe to updates
    @client.subscribe_to_location_movement(clocation.id).should be(true)
    Runner.instance.locations.first.movement_callbacks.size.should == 1
    Runner.instance.locations.first.movement_callbacks[0].class.should == Callbacks::Movement

    ## delay briefly allowing for updates
    sleep 2

    times_moved.should be > 0

    # stop the runner
    Runner.instance.stop
  end

  it "should permit receiving location proximity events" do
    # start the runner here, to actual move location / process callbacks
    Runner.instance.clear
    Runner.instance.start :async => true

    # create the locations
    clocation1 = Location.new :id => 300
    clocation2 = Location.new :id => 600
    @client.create_location(clocation1).id.should == clocation1.id
    @client.create_location(clocation2).id.should == clocation2.id

    # update
    location1 = Location.new :id => clocation1.id, :x => 0, :y => 0, :z => 0
    location2 = Location.new :id => clocation2.id, :x => 0, :y => 0, :z => 100
    @client.update_location(location1).should be(true)
    @client.update_location(location2).should be(true)

    proximity_triggered = false

    # handle location_moved method
    @client.on_locations_proximity = lambda { |loc1, loc2|
      location1.id.should == clocation1.id
      location2.id.should == clocation2.id
      proximity_triggered = true
    }

    ## subscribe to updates
    @client.subscribe_to_locations_proximity(clocation1.id, clocation2.id, "proximity", 10).should be(true)
    Runner.instance.locations.first.proximity_callbacks.size.should == 1
    Runner.instance.locations.first.proximity_callbacks[0].class.should == Callbacks::Proximity

    # FIXME test all proximity events: proximity, entered_proximity, left_proximity

    ## delay briefly allowing for updates
    sleep 2

    proximity_triggered.should be_false

    # update location to satisfy proximity criteria
    location2.z = 5
    @client.update_location(location2).should be(true)

    ## delay briefly allowing for updates
    sleep 2

    proximity_triggered.should be_true

    # stop the runner
    Runner.instance.stop
  end

end
