# Cosmos remote cosmos tracking operations
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO provide mechanism which to create necessary permissions
#      to invoke operations on remote queue

require 'thread'

module Cosmos

# Utility to fetch remotely tracked entities and their children
# from a remote cosmos server via AMQP.
class RemoteCosmosManager
  class << self
    # @!group Config options

    # Username to login to remote node with
    # @!scope class
    attr_accessor :user

    # Password to login to remote node
    # @!scope class
    attr_accessor :password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.user     = config.remote_cosmos_manager_user
      self.password = config.remote_cosmos_manager_password
    end

    # @!endgroup
  end

  # RemoteCosmosManager initializer
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
      @nodes[queue] = RJR::AMQPNode.new :broker => broker, :node_id => "cosmos-remote-#{node_id}"
      #@nodes[queue].listen

      # TODO incorporate a rjr timeout?
      session = @nodes[queue].invoke_request(queue, 'users::login', user)
      @nodes[queue].message_headers['session_id'] = session.id
    end

    @nodes[queue]
  end

  # Retrieve and return entity from its specified remote queue
  #
  # @param [CosmosEntity] entity entity which to retrieve from the queue specified by its remote_queue attribute
  # @return result of 'cosmos::get_entity' call on remote_queue
  def get_entity(entity)
    @lock.synchronize{
      entity_type = entity.class.to_s.downcase.underscore.split('/').last.intern
      node = remote_node_for(entity.remote_queue)
      return node.invoke_request(entity.remote_queue, 'cosmos::get_entity', 'of_type', entity_type, 'with_name', entity.name)
    }
  end

  # Create entity on its specified remote queue
  #
  # @param [CosmosEntity] entity to create via the queue specified by its remote_queue attribute
  # @param [String] parent_name name on entity's parent
  def create_entity(entity, parent_name)
    @lock.synchronize{
      trq = entity.remote_queue
      entity.remote_queue = nil

      node = remote_node_for(trq)
      node.invoke_request(trq, 'cosmos::create_entity', entity, parent_name)

      entity.remote_queue = trq
    }
  end

  # Set resource on remote entity (TBD)
  def set_resource(entity, resource, quantity)
  end

  # Get a remote entity's resources (TBD)
  def get_resource_sources(entity)
  end

end
end
