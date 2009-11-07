# simrpc tests, tests the simrpc interface
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

class SimrpcTest < Test::Unit::TestCase
  def setup
    # setup simrpc endpoints
    @server = Server.new :schema_file => Conf.schema_file
    @client = Client.new :schema_file => Conf.schema_file

    # in reality associated class would be something other than a movement strategy
    # like a car or city or something, but this is convenient since its already in our db
    @associated = Stopped.new :step_delay => 5
    @associated.save!

    # setup a location for subsequent use
    @parent = Location.new :movement_strategy => MovementStrategy.stopped
    #@parent.save!
    @location = Location.new :parent => @parent, :x => 150, :y => 300, :z => 600,
                             :entity => @associated
    @location.save!
    @location_id = @location.id
  end

  def teardown
  end

  def test_register_location
    success = @client.register_location(@location_id)
    assert success

    success = @client.request :request_target => :register,
                              :location => @location
    assert success
  end

  def test_get_location
     success = @client.register_location(@location_id)
     assert success

     loc = @client.get_location(@location_id)
     assert !loc.nil?
     assert_equal 150, loc.x
     assert_equal 300, loc.y
     assert_equal 600, loc.z
     assert_equal 5, loc.entity.step_delay
     assert_equal Stopped, loc.entity.class

     loc = @client.request :request_target => :get, :location => @location
     assert !loc.nil?
     assert_equal 150, loc.x
  end

  def test_update_location
     success = @client.register_location(@location_id)
     assert success

     # update location
     location = Location.new :x  => 50
     location.id = @location_id
     success = @client.update_location(location)
     assert success

     # set movement strategy
     location = Location.new
     location.id = @location_id
     location.movement_strategy = Linear.new(:step_delay => 10,
                                             :speed      => 15,
                                             :direction_vector_x => 1,
                                             :direction_vector_y => 1,
                                             :direction_vector_z => 1)
     success = @client.update_location(location)
     assert success

     # make sure all attributes were updated properly
     location = @client.get_location(@location_id)
     assert_equal 50, location.x
     assert_equal 300, location.y
     assert_equal 600, location.z
     assert_equal "Linear", location.movement_strategy.type
     assert_equal 15, location.movement_strategy.speed

     # update movement strategy
     location.movement_strategy = Linear.new(:speed  => 50)
     success = @client.update_location(location)
     assert success

     # update invalid location
     success = @client.update_location(nil)
     assert !success
  end

  def test_save_location
     success = @client.register_location(@location_id)
     assert success

     success = @client.save_location @location_id
     assert success

     success = @client.save_location nil
     assert !success
  end

  def test_subscribe_to_location
     # register the location
     success = @client.register_location(@location_id)
     assert success

     # set a linear movement strategy
     location = Location.new
     location.id = @location_id
     location.movement_strategy = Linear.new(:step_delay => 1,
                                             :speed      => 15,
                                             :direction_vector_x => 1,
                                             :direction_vector_y => 0,
                                             :direction_vector_z => 0)
     success = @client.update_location(location)
     assert success

     times_moved = 0

     # handle location_moved method
     @client.on_location_received = lambda { |location|
       times_moved += 1
     }

     # subscribe to updates
     success = @client.subscribe_to_location(@location_id)
     assert success

     # delay briefly allowing for updates
     sleep 5

     assert times_moved > 0
  end
end
