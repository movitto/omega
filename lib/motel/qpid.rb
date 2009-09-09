# initialize the amqp subsystem using apache qpid
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'qpid'
require 'socket'

require 'motel/common'
require 'motel/semaphore'

module Motel

unless defined? MESSAGE_DATA_LENGTH_DIGITS
 # fixed number of digits to convey the lengths of message data fields
 MESSAGE_DATA_LENGTH_DIGITS    = 4                 
 MESSAGE_DATA_LENGTH_FORMATTER = "%0" + MESSAGE_DATA_LENGTH_DIGITS.to_s + "d"
 def format_message_data_field(data)
   (MESSAGE_DATA_LENGTH_FORMATTER % data.to_s.size) + data.to_s
 end
end

# a base message interface which can be used to create 
# and receive qpid passable messages. Should be subclassed
# to create specific messages
#
# ex
#
# class TestMessage < MessageBase
#   define_message :foo, :some_string, :some_int
#   def initialize
#     foo_handler = Proc.new { |str, int|
#        puts str + " " + int.to_s
#     }
#   end
# end
#
class MessageBase
 protected

  # define a new named message type, creating a
  # message-generator class-method and a optional 
  # message handler callback. Both the generator
  # class method and the callback should be 
  # procedures that take the specified params
  #
  # example usage
  #  class MyMessages
  #    defined_message :test, :some_string, :some_int
  #  end
  #
  # will result in the following being added to the class
  #    attr_writer :test_handler # set to a Proc to be invoked when test messages are received with the msg params
  #    def self.test(params)
  #      # creates an returns a new test message instance w/ the specified params
  #    end
  #
  def self.define_message(name, *params)
     # define member variable and setter for callable message handler
     attr_writer (name.to_s + "_handler").intern

     # create static method to create the message from passed in params
     (class << self; self; end).send(:define_method, name) do |*mparams|
        return nil if mparams.size > params.size

        # msg format is name_len name param1_len param1 param2_len param2...
        result = format_message_data_field(name)
        mparams.each{ |param|
          serialized = Marshal.dump(param) # TODO would be nice to do this in a language-agnostic way
          result += format_message_data_field(serialized)
        }

        return result
     end
  end

 public

  # parse a message received, pull out the name
  # and invoke appropriate callback (if set) with
  # applicable parameters
  def parse(msg)
    content = msg.body

    # grab the message name
    len  = content.slice!(0..MESSAGE_DATA_LENGTH_DIGITS-1).to_i
    name = content.slice!(0..len-1)

    # grab the message params
    params = []
    until content.size == 0
      len  = content.slice!(0..MESSAGE_DATA_LENGTH_DIGITS-1).to_i
      params.push Marshal.load(content.slice!(0..len.to_i-1)) # TODO would be nice to do this in a language-agnostic way
    end

    # determine if corresponding message handler is set
    handler = instance_variable_get('@' + name + "_handler")
    unless handler.nil?
      # pad the parameters if need be
      # always set the last excess param
      # to the routing key, set others
      # to nil
      num_params = handler.arity
      if params.size < num_params
        nils = num_params - (params.size + 1)
        (0...nils).each{ params.push nil }
        params.push msg.get(:message_properties).reply_to.routing_key
      end

      handler.call params
    end
  end
end

# QpidBase class, adapts qpid base connection 
# interface to the motel library. connect to
# specified qpid broker / port
class QpidBase
  
  # create the qpid base connection with the specified broker / port
  # or config file. If no config is specifed one will be read for the 
  # MOTEL_AMQP_CONF ENV variable.
  # specify :broker and :port arguments to directly connect to those
  # specify :config argument to use that yml file
  # specify MOTEL_AMQP_CONF environment variable to use that yml file
  def initialize(args = {})
    ENV['MOTEL_ENV'] = "production" if ENV['MOTEL_ENV'].nil?
    env = ENV['MOTEL_ENV'] 

    # if no id specified generate a new uuid
    @node_id = args[:id].nil? ? gen_uuid : args[:id]

    # get the broker/port
    broker = args[:broker] if args.has_key? :broker
    port  = args[:port]    if args.has_key? :port

    if broker.nil? || port.nil?
      config      = args.has_key?(:config) ? args[:config] : ENV['MOTEL_AMQP_CONF']
      amqpconfig = YAML::load(File.open(config))
      broker = amqpconfig[env]["broker"] if broker.nil?
      port   = amqpconfig[env]["port"]   if port.nil?
    end

    ### create underlying tcp connection
    $logger.debug " connecting to amqp broker " + broker + " on port " + port.to_s
    @conn = Qpid::Connection.new(TCPSocket.new(broker,port))
    @conn.start
    
    ### connect to qpid broker
    $logger.debug " creating amqp session " + @node_id.to_s
    @ssn = @conn.session(@node_id)
  end

  # terminate operations and close constructs
  def terminate
     @ssn.close
  end
end

# QpidNode class, represents an enpoint  on a qpid
# network which has its own exchange and queue
# which it listens on
class QpidNode < QpidBase

 public
  
  # a node can have children nodes mapped to by keys
  attr_accessor :children

  # initialize QpidBase connection then establish location qpid server
  # QpidExchange and QpidQueue and start listening for requests
  # specify :id parameter to set id, else it will be set to a uuid just
  # created
  def initialize(args = {})
     super(args)
     @children = {}

     @accept_lock = Semaphore.new(1)

     # qpid constructs that will be created for node
     @exchange     = args[:exchange].nil?    ? @node_id.to_s + "-exchange"    : args[:exchange]
     @queue        = args[:queue].nil?       ? @node_id.to_s + "-queue"       : args[:queue]
     @local_queue  = args[:local_queue].nil? ? @node_id.to_s + "-local-queue" : args[:local_queue]
     @routing_key  = @queue

     if @ssn.exchange_query(@exchange).not_found
       $logger.debug " declaring message exchange " + @exchange
       @ssn.exchange_declare(@exchange, :type => "direct")
     end

     if @ssn.queue_query(@queue).queue.nil?
       $logger.debug " declaring message queue " + @queue
       @ssn.queue_declare(@queue)
     end

     @ssn.exchange_bind(:exchange => @exchange,
                        :queue    => @queue,
                        :binding_key => @routing_key)
  end
                       
  # instruct QpidServer to start accepting requests 
  # asynchronously and immediately return
  # specified expected_message should be Message instance with necessary handlers set
  def async_accept(expected_message)
     # TODO permit a QpidNode to accept messages from multiple sources
     @accept_lock.wait

     # subscribe to the queue
     @ssn.message_subscribe(:destination => @local_queue, 
                            :queue => @queue,
                            :accept_mode => @ssn.message_accept_mode.none)
     @incoming = @ssn.incoming(@local_queue)
     @incoming.start

     $logger.debug " subscribing to message queue " + @queue

     # start receiving messages
     @incoming.listen{ |msg|
        $logger.debug " received message \"" + msg.body + "\" via queue " + @queue
        expected_message.parse msg 
     }
  end

  # block until accept operation is complete
  def join
     @accept_lock.wait
  end

  # instructs QpidServer to stop accepting, blocking
  # untill all accepting operations have terminated
  def terminate
    unless @incoming.nil?
      @incoming.stop
      @incoming.close
      @accept_lock.signal
    end
    super
    # TODO undefine the @queue/@exchange
  end

  # send a message to the specified routing_key
  def send_message(routing_key, message)
    dp = @ssn.delivery_properties(:routing_key => routing_key)
    mp = @ssn.message_properties( :content_type => "text/plain")
    rp = @ssn.message_properties( :reply_to => 
                                  @ssn.reply_to(@exchange, @routing_key))
    msg = Qpid::Message.new(dp, mp, rp, message)

    $logger.debug " sending message \"" + message.to_s + "\" to " + routing_key
    
    # send it
    @ssn.message_transfer(:message => msg)
  end

end

end # module Motel
