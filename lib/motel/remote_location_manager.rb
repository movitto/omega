# Motel remote location tracking operations
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO provide mechanism which to create necessary permissions
#      to invoke operations on remote queue

require 'thread'

module Motel

# Utility to fetch remotely tracked entities and their children
# from a remote motel server via AMQP.
class RemoteLocationManager
  class << self
    # @!group Config options

    # Username to login to remote node with
    # @!scope class
    attr_accessor :user

    # Password to login to remote node with
    # @!scope class
    attr_accessor :password

    # @!endgroup
  end

  # RemoteLocationManager initializer
  def initialize
    @nodes = {}
    @lock  = Mutex.new
  end

  # Return a RJR::AMQPNode to send messages to the specified queue
  #
  # An AMQPNode will be instantiated for each different queue, and
  # an internal array is used to keep track of them.
  # @param [String] queue name of queue to connect to
  # @return RJR::AMQPNode to be used to send and received messages to/from queue
  def remote_node_for(queue)
    unless @nodes.has_key?(queue)
      # FIXME lookup which broker is running queue & user credentials to use
      #       (intially via config file, but later via service)
      broker = 'localhost'
      user = Users::User.new :id => self.class.user, :password => self.class.password

      node_id = Motel.gen_uuid
      @nodes[queue] = RJR::AMQPNode.new :broker => broker, :node_id => "motel-remote-#{node_id}"
      #@nodes[queue].listen

      # TODO incorporate a rjr timeout?
      session = @nodes[queue].invoke_request(queue, 'users::login', user)
      @nodes[queue].message_headers['session_id'] = session.id
    end

    @nodes[queue]
  end

  # Retrieve and return location from its specified remote queue
  #
  # @param [Motel::Location] location location which to retrieve from the queue specified by its remote_queue attribute
  # @return result of 'motel::get_location' call on remote_queue
  def get_location(location)
    @lock.synchronize{
      node = remote_node_for(location.remote_queue)
      rloc = node.invoke_request(location.remote_queue, 'motel::get_location', 'with_id', location.id)
      return rloc
    }
  end

  # Create location on its specified remote queue
  #
  # @param [Motel::Location] location location to create via the queue specified by its remote_queue attribute
  def create_location(location)
    @lock.synchronize{
      trq = location.remote_queue
      location.remote_queue = nil

      node = remote_node_for(trq)
      node.invoke_request(trq, 'motel::create_location', location)

      location.remote_queue = trq
    }
  end

  # Update location via its remote queue
  #
  # @param [Motel::Location] location location to update via its remote_queue attribute
  def update_location(location)
    @lock.synchronize{
      trq = location.remote_queue
      location.remote_queue = nil

      node = remote_node_for(trq)
      node.invoke_request(trq, 'motel::update_location', location)

      location.remote_queue = trq
    }
  end

  # Track the movement of a remote location (TBD)
  def track_movement
  end

  # Track the proximity of a remote location (TBD)
  def track_proximity
  end

end
end
