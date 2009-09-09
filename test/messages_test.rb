# messages tests, tests the messages module
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

class MessagesTest < Test::Unit::TestCase
  def setup
    Location.delete_all

    # create a new server / client / runner
    @server = QpidNode.new :id => "test"
    @client = QpidNode.new
    @runner = Runner.new

    # setup the messages handlers, begin accepting messages
    @expected_request = RequestMessage.new
    @expected_request.register_handlers @runner, @server
    @server.async_accept @expected_request

    # setup a location for subsequent use
    @parent = Location.new :movement_strategy => MovementStrategy.stopped
    #@parent.save!
    @location = Location.new :parent => @parent, :x => 150, :y => 300, :z => 600
    @location.save!
    @location_id = @location.id
  end

  def teardown
    # terminate server operations
    @server.terminate unless @server.nil?
  end

  # TODO run these tests w/ multiple clients
  # to test parallel execution

  def test_register_location
    # status response we're currently expecting to receive
    expected_result = "success"

    # block until we receive responses
    msg_lock = Semaphore.new(1)
    msg_lock.wait()

    # status and location response handlers
    expected_response = ResponseMessage.new
    expected_response.status_handler = Proc.new { |status|
       assert_equal expected_result, status.to_s
       msg_lock.signal()
    }
    @client.async_accept expected_response

    # send register location reuquest
    request = RequestMessage.register_location @location_id
    @client.send_message "test-queue", request
    msg_lock.wait()
    assert_equal 1, @runner.locations.size

    # send register location reuquest again
    request = RequestMessage::register_location @location_id
    @client.send_message "test-queue", request
    msg_lock.wait()
    assert_equal 1, @runner.locations.size

    # terminate operations
    @client.terminate
  end

  def test_get_location
    # status response we're currently expecting to receive
    expected_result = "success"
    
    # block until we receive responses
    msg_lock = Semaphore.new(1)
    msg_lock.wait()

    # make sure we receive both a status and a location message
    status_message_received = location_message_received = false

    # status and location response handlers
    expected_response = ResponseMessage.new
    expected_response.status_handler = Proc.new { |status|
       assert_equal expected_result, status.to_s
       status_message_received = true
       msg_lock.signal()
    }
    expected_response.location_handler = Proc.new { |location|
       #assert_equal @location, location
       location_message_received = true
       msg_lock.signal()
    }
    @client.async_accept expected_response

    # send register location reuquest
    request = RequestMessage.register_location @location_id
    @client.send_message "test-queue", request
    msg_lock.wait()
    assert status_message_received
    status_message_received = false

    # send a get lcoation rquest
    request = RequestMessage::get_location @location_id
    @client.send_message "test-queue", request
    msg_lock.wait()
    assert location_message_received

    # TODO verify children locations are retreived as well

    # send an invalid get lcoation rquest
    expected_result = "failed"
    request = RequestMessage::get_location -1
    @client.send_message "test-queue", request
    msg_lock.wait()
    assert status_message_received

    # terminate operations
    @client.terminate
  end

  def test_update_location
    # status response we're expecting
    expected_result = "success"

    # block until messages are received
    msg_lock = Semaphore.new(1)
    msg_lock.wait()

    # register status response handler
    expected_response = ResponseMessage.new
    expected_response.status_handler = Proc.new { |status|
       assert_equal expected_result, status.to_s
       msg_lock.signal()
    }
    @client.async_accept expected_response

    # register the locatino
    request = RequestMessage.register_location @location_id
    @client.send_message "test-queue", request
    msg_lock.wait()

    # create a new location w/ updated attributes
    location = Location.new :x  => 50
    location.id = @location_id

    # update managed location
    request = RequestMessage::update_location location
    @client.send_message "test-queue", request
    msg_lock.wait()

    # set new movement strategy
    location = Location.new
    location.id = @location_id
    movement_strategy = Linear.new(:step_delay => 10, 
                                   :speed      => 15,
                                   :direction_vector_x => 1,
                                   :direction_vector_y => 1,
                                   :direction_vector_z => 1)
    request = RequestMessage::update_location location, movement_strategy
    @client.send_message "test-queue", request
    msg_lock.wait()

    # update movement strategy
    movement_strategy = Linear.new(:speed  => 50)
    request = RequestMessage::update_location location, movement_strategy
    @client.send_message "test-queue", request
    msg_lock.wait()

    # update invalid location
    expected_result = "failed"
    request = RequestMessage::update_location nil
    @client.send_message "test-queue", request
    msg_lock.wait()

    # TODO verify updating other attributes, verify getting the updated location

    @client.terminate
  end

  def test_save_location
    # status response we're expecting
    expected_result = "success"

    # block until messages are received
    msg_lock = Semaphore.new(1)
    msg_lock.wait()

    # register status response handler
    expected_response = ResponseMessage.new
    expected_response.status_handler = Proc.new { |status|
       assert_equal expected_result, status.to_s
       msg_lock.signal()
    }
    @client.async_accept expected_response

    # register the locatino
    request = RequestMessage.register_location @location_id
    @client.send_message "test-queue", request
    msg_lock.wait()

    # save the location
    request = RequestMessage::save_location @location_id
    @client.send_message "test-queue", request
    msg_lock.wait()

    # try to save invalid location
    expected_result = "failed"
    request = RequestMessage::save_location -1
    @client.send_message "test-queue", request
    msg_lock.wait()

    # terminate operations
    @client.terminate
  end

  def test_subscribe_to_location
    # status response we're expecting
    expected_result = "success"

    # block until messages are received
    msg_lock = Semaphore.new(1)
    msg_lock.wait()

    expected_response = ResponseMessage.new
    expected_response.status_handler = Proc.new { |status|
       assert_equal expected_result, status.to_s
       msg_lock.signal()
    }
    @client.async_accept expected_response

    # register the locatino
    request = RequestMessage.register_location @location_id
    @client.send_message "test-queue", request
    msg_lock.wait()

    # set its movement strategy to linear

    # subscribe to the location
    request = RequestMessage::subscribe_to_location @location_id
    @client.send_message "test-queue", request
    msg_lock.wait()

    ssn = @server.instance_variable_get('@ssn')
    assert !ssn.exchange_query("location" + @location_id.to_s + "-updates-exchange").not_found
    assert !ssn.queue_query("location"    + @location_id.to_s + "-updates-queue").queue.nil?
  # TODO how do I get this:
  #  http://www.redhat.com/docs/en-US/Red_Hat_Enterprise_MRG/1.1/html/python/public/qpid.generator.ControlInvoker_0_10-class.html#exchange_bound_result
  #  binding_result = @server.ssn.binding_query("location"+ @location_id.to_s + "-queue")
  #  assert !binding_result.exchange_not_found?
  #  assert !binding_result.queue_not_found?
  #  assert !binding_result.queue_not_matched?
  #  assert !binding_result.key_not_found?

    # make sure a movement callback handler has been registered w/ the location
    @runner.locations.each{ |l|
      if l.id == @location_id
        assert_equal 1, l.movement_strategy.movement_callbacks.size
        break
      end
    }

    @client.terminate
  end

end
