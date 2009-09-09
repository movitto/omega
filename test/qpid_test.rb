# qpid tests, tests the qpid interface
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel/semaphore'

class QpidTestMessage < MessageBase
    define_message :test, :some_string, :an_int
end

class QpidTest < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_define_message
    #assert QpidTestMessage.instance_variable_defined?("@test_handler")
    assert QpidTestMessage.instance_methods.include?("test_handler=")
    assert QpidTestMessage.methods.include?("test")
    #assert_equal 2, QpidTestMessage.method(:test).arity
  end

  def test_construct_message
    msg = QpidTestMessage::test "foobar", 420
    assert_equal(("%04d" % "test".size) + "test" + 
                 ("%04d" % Marshal.dump("foobar").size) + Marshal.dump("foobar") +
                 ("%04d" % Marshal.dump(420).size)    + Marshal.dump(420), msg)
  end

  def test_connect_to_broker
    # TODO test w/ broker/port & specified conf
    qpid = QpidBase.new :id => "test1"
    ssn = qpid.instance_variable_get('@ssn')
    id = qpid.instance_variable_get('@node_id')
    assert ! ssn.error?
    assert ! ssn.closed
    assert_equal "test1", id
  end

  def test_parse_message
    # test message parser callback
    msg = QpidTestMessage::test "foobar", 420
    parser = QpidTestMessage.new
    parser.test_handler = Proc.new { |str,int|
       assert_equal "foobar", str
       assert_equal 420, int.to_i
    }
    qpid = QpidBase.new
    ssn = qpid.instance_variable_get('@ssn')
    rp = ssn.message_properties( :reply_to => 
                                  ssn.reply_to("test-reply-xcg", "test-reply-route") )
    qmsg = Qpid::Message.new rp, msg
    parser.parse qmsg


    # test message parser callback w/ reply_to
    parser.test_handler = Proc.new { |str, int, reply_to|
       assert_equal "test-reply-route", reply_to
    }
    parser.parse qmsg
  end

  def test_establish_exchange_and_queue
     node = QpidNode.new :id => "test2"

     exchange = node.instance_variable_get("@exchange")
     assert_equal "test2-exchange", exchange

     queue = node.instance_variable_get("@queue")
     assert_equal "test2-queue", queue

     local_queue = node.instance_variable_get("@local_queue")
     assert_equal "test2-local-queue", local_queue

     routing_key = node.instance_variable_get("@routing_key")
     assert_equal "test2-queue", routing_key

     ssn = node.instance_variable_get('@ssn')
     assert !ssn.exchange_query("test2-exchange").not_found
     assert !ssn.queue_query("test2-queue").queue.nil?

     # TODO how do I get this:
     #  http://www.redhat.com/docs/en-US/Red_Hat_Enterprise_MRG/1.1/html/python/public/qpid.generator.ControlInvoker_0_10-class.html#exchange_bound_result
     #binding_result = ssn.binding_query("test2-queue")
     #assert !binding_result.exchange_not_found?
     #assert !binding_result.queue_not_found?
     #assert !binding_result.queue_not_matched?
     #assert !binding_result.key_not_found?
  end

  def test_transmit_message
     i = rand(100)

     server  = QpidNode.new :id => "server"
     request = QpidTestMessage.new
     request.test_handler = Proc.new { |str, int, reply_to|
        assert_equal "request", str
        assert_equal i, int.to_i
        server.send_message(reply_to, QpidTestMessage.test("reply", -i))
     }
     server.async_accept request

     finished_lock = Semaphore.new(1)
     finished_lock.wait()

     client = QpidNode.new :id => 'client'
     response = QpidTestMessage.new
     response.test_handler = Proc.new { |str, int, reply_to|
        assert_equal "reply", str
        assert_equal -i, int.to_i
        finished_lock.signal()
     }
     client.async_accept response

     outgoing = QpidTestMessage.test("request", i)
     client.send_message("server-queue", outgoing)

     finished_lock.wait()
  end
end
