# Omega Server Proxy Entity and Node definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rjr/nodes/easy'
require 'omega/server/registry'

module Omega
module Server

# Omega Proxy Entity, protects entity access using a registry
class ProxyEntity
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

  def initialize(entity, registry)
    @entity = entity
    @registry = registry
  end

  protected

  def method_missing(name, *args, &block)
    ret = nil
    old_entity = nil
    @registry.safe_exec { |entities|
      old_entity = JSON.parse(@entity.to_json)
      ret = @entity.send(name, *args, &block)
    }
    # TODO only invoke if entity changed?
    @registry.raise_event(:updated, @entity, old_entity)
    ret
  end
end

# Omega Proxy Node, proxies request to a remote omega server,
# maintaining a session to do so
class ProxyNode
  class << self
    def set_config(config)
      # create nodes for target by 'proxy_to' in config
      @nodes ||=
        config.proxy_to.to_h.collect { |id, opts| # XXX to_h needed,
                                                  # see fixme in config class
          ProxyNode.new :id       => id.to_s,
                        :node_id  => config.proxy_node_id,
                        :user_id  => opts[:user_id],
                        :password => opts[:password],
                        :dst      => opts[:dst]
        } if config.proxy_to
    end
  end

  # return node for specified dst
  def self.with_id(id)
    @nodes ? @nodes.find { |n| n.id == id } : nil
  end

  attr_accessor :id
  attr_accessor :rjr_node
  attr_accessor :user
  attr_accessor :dst
  attr_accessor :login_time

  # required for attr_from_args below
  attr_accessor :node_id
  attr_accessor :user_id
  attr_accessor :password # XXX

  def initialize(args = {})
    attr_from_args args, :id         => nil,
                         :dst        => nil,
                         :node_id    => nil,
                         :user_id    => nil,
                         :password   => nil,
                         :login_time => nil

    @user = Users::User.new :id => @user_id, :password => @password
    @rjr_node = RJR::Nodes::Easy.node_type_for(dst).new(:node_id => @node_id)
  end

  def login
    # unless !@login_time.nil? && Time.now - @login_time < SESSION_EXPIRATION TODO - remote session expiration may be different than local
    session = invoke 'users::login', @user
    @rjr_node.message_headers['session_id'] = session.id
    @rjr_node.message_headers['source_node'] = @user.id
    @login_time = Time.now
    self
  end

  def invoke(*args)
    @rjr_node.invoke @dst, *args
  end

  def notify(*args)
    @rjr_node.notify @dst, *args
  end
end


end # module Server
end # module Omega
