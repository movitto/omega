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
    location_id = 10
    @client.create_location(location_id).should be(true)
    Runner.instance.locations.size.should == locations + 1

    loc = @client.get_location(location_id)
    loc.should_not be_nil
    loc.id.should be(location_id)
  end

  it "should permit updating a location" do
    location_id = 20
    @client.create_location(location_id).should be(true)
    @client.update_location(Location.new(:id => location_id, :x => 150, :y => 300, :z => -600)).should be(true)

    loc = @client.get_location(location_id)
    loc.should_not be_nil
    loc.x.should be(150)
    loc.y.should be(300)
    loc.z.should be(-600)

    loc = @client.request :get_location, location_id
    loc.should_not be_nil
    loc.x.should be(150)
  end

  it "should permit receiving location movement updates" do
    # start the runner here, to actual move location / process callbacks
    Runner.instance.clear
    Runner.instance.start :async => true

    # create the location
    location_id = 30
    @client.create_location(location_id).should be(true)

    ## set a linear movement strategy
    location = Location.new
    location.id = location_id
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
    @client.subscribe_to_location_movement(location_id).should be(true)
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
    location1_id = 300 ; location2_id = 600
    @client.create_location(location1_id).should be(true)
    @client.create_location(location2_id).should be(true)

    # update
    location1 = Location.new :id => location1_id, :x => 0, :y => 0, :z => 0
    location2 = Location.new :id => location2_id, :x => 0, :y => 0, :z => 100
    @client.update_location(location1).should be(true)
    @client.update_location(location2).should be(true)

    proximity_triggered = false

    # handle location_moved method
    @client.on_locations_proximity = lambda { |loc1, loc2|
      location1.id.should == location1_id
      location2.id.should == location2_id
      proximity_triggered = true
    }

    ## subscribe to updates
    @client.subscribe_to_locations_proximity(location1_id, location2_id, 10).should be(true)
    Runner.instance.locations.first.proximity_callbacks.size.should == 1
    Runner.instance.locations.first.proximity_callbacks[0].class.should == Callbacks::Proximity

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
