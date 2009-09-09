# motel network module
#
# Defines a typical motel server and client
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel/messages'

# FIXME write tests for this module

module Motel

# Motel::Server defines a server endpoint which manages locations
# via use of the Runner class and listens for and handles instances
# of RequestMessage messages, performing the target operation and 
# returing an instance of a ReponseMessage message, as defined in
# the motel/messages.rb module
class Server

  # simply initialize the server class, and optionally block 
  # using the join method, everything else is handled
  def initialize
    
    # load and start the default location set
    @runner = Loader.Load

    # create a qpid node for the server location requests
    @server = QpidNode.new :id => "location-request"

    # create a request message and register handlers
    request = RequestMessage.new
    request.register_handlers(@runner, @server)

    # begin listening for and handling requests
    @server.async_accept request

    # TODO some sort or graceful killing mechanism
  end

  # block until the server is terminated
  def join
    @server.join
  end

end # class Server

# Motel::Client defines a client endpoint that constructs a RequestMessage
# message and sends it to the server, before waiting for the response and 
# performing any other specific-request related tasks
class Client
 
  # Initialize the client with any number of params. These may include
  #   * :request_target => [:get, :register, :save, :update] specify request to send to server, this argument must be present
  #   * :location => <Location instance> - location to send to server, requires an id for all operations
  #   * :movement_strategy_type => <string> - of movement_strategy.type to send to server
  def initialize(params = {})
    request_target            = params[:request_target]
    location                  = params[:location]
    movement_strategy_type    = params[:movement_strategy_type]
    movement_strategy_encoded = params[:movement_strategy_encoded]

    # message we're going to be sending to the server
    request = nil
    if request_target == :get
      request = RequestMessage::get_location location.id

    elsif request_target == :register
      request = RequestMessage::register_location location.id

    elsif request_target == :save
      request = RequestMessage::save_location location.id

    elsif request_target == :update
      if movement_strategy_type.nil? && movement_strategy_encoded.nil?
        movement_strategy = nil
      elsif !movement_strategy_type.nil? && !movement_strategy_encoded.nil?
        # FIXME
        #movement_strategy = MovementStrategy.factory(movement_strategy_type).from_s(movement_strategy_encoded)
      elsif !movement_strategy_type.nil? 
        movement_strategy = MovementStrategy.factory(movement_strategy_type).new
      elsif !movement_strategy_encoded.nil? 
        # TODO
      end
      request = RequestMessage::update_location location, movement_strategy

    elsif request_target == :subscribe
      request = RequestMessage::subscribe_to_location location.id

    end

    # create a qpid node
    @client = QpidNode.new

    # block until we are completed
    completed_lock = Semaphore.new(1)
    completed_lock.wait

    # create a request message and register handlers
    response = ResponseMessage.new
    response.location_handler= Proc.new { |location|
      puts "Location received: " + location.to_s
      completed_lock.signal unless request_target == :subscribe
    }
    response.status_handler= Proc.new { |status, reply_to|
      puts "Status received: " + status.to_s

      # if we are updating subscribe to updates queue, else release complete_lock
      if request_target == :subscribe
         @subscription_client = QpidNode.new :queue => reply_to
         @subscription_client.async_accept response
      end
      completed_lock.signal
    }

    # begin listening for responses handing them 
    # with the handlers specified above
    @client.async_accept response

    # send the request message to the location request queue
    @client.send_message "location-request-queue", request

    # wait until we are done
    completed_lock.wait
  end

  # block until the server is terminated
  def join
    @client.join
  end
end

end # module Motel

