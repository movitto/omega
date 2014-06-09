# Initialize the stats subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/exceptions'
require 'omega/server/dsl'

require 'users/rjr/init'
require 'users/user'
require 'rjr/nodes/local'

module Stats
module RJR
  include Stats
  include Omega#::Exceptions
  include Omega::Server::DSL

  class << self
    # @!group Config options

    # Unique universe identifier
    attr_accessor :universe_id

    # User to use to communicate w/ other modules over the local rjr node
    attr_accessor :stats_rjr_username

    # Password to use to communicate w/ other modules over the local rjr node
    attr_accessor :stats_rjr_password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.universe_id         = config.universe_id    || Motel.gen_uuid # XXX gen_uuid should be moved into omega/common
      self.stats_rjr_username  = config.stats_rjr_user
      self.stats_rjr_password  = config.stats_rjr_pass
    end

    # @!endgroup
  end

  def self.user_registry
    Users::RJR.registry
  end

  def user_registry
    Stats::RJR.user_registry
  end

  PRIVILEGES =
    [['view',   'manufactured_entities'],
     ['view',   'cosmos_entities'],
     ['view',   'users'],
     ['view',   'missions']]

  def self.user
    @user ||= Users::User.new(:id       => Stats::RJR.stats_rjr_username,
                              :password => Stats::RJR.stats_rjr_password,
                              :registration_code => nil)
  end

  def user
    Stats::RJR.user
  end

  def self.node
    @node ||= ::RJR::Nodes::Local.new :node_id => self.user.id
  end

  def node
    Stats::RJR.node
  end
end
end

def dispatch_stats_rjr_init(dispatcher)
  # setup Stats::RJR module
  rjr = Object.new.extend(Stats::RJR)
  rjr.node.dispatcher = dispatcher
  rjr.node.dispatcher.env /stats::.*/, Stats::RJR
  rjr.node.dispatcher.add_module('stats/rjr/get')
  rjr.node.message_headers['source_node'] = 'stats'

  begin rjr.node.invoke('users::create_user', rjr.user)
  rescue Exception => e ; end

  # grant stats user extra permissions
  role_id = "user_role_#{rjr.user.id}"
  Stats::RJR::PRIVILEGES.each { |p,e|
     rjr.node.invoke('users::add_privilege', role_id, p, e)
   }

  session = rjr.node.invoke('users::login', rjr.user)
  rjr.node.message_headers['session_id'] = session.id
end
