# Initialize the cosmos subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/registry'
require 'omega/exceptions'
require 'omega/server/dsl'
require 'users/rjr/init'

module Cosmos::RJR
  include Cosmos
  include Omega#::Exceptions
  include Omega::Server::DSL

  ######################################## Config

  class << self
    # @!group Config options

    # User to use to communicate w/ other modules over the local rjr node
    attr_accessor :cosmos_rjr_username

    # Password to use to communicate w/ other modules over the local rjr node
    attr_accessor :cosmos_rjr_password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.cosmos_rjr_username  = config.cosmos_rjr_user
      self.cosmos_rjr_password  = config.cosmos_rjr_pass
    end

    # @!endgroup
  end

  ######################################## Cosmos::RJR data

  PRIVILEGES =
    [['view',   'locations'],
     ['create', 'locations']]

  def self.user
    @user ||= Users::User.new(:id       => Cosmos::RJR.cosmos_rjr_username,
                              :password => Cosmos::RJR.cosmos_rjr_password,
                              :registration_code => nil)
  end

  def user
    Cosmos::RJR.user
  end

  def self.node
    @node ||= ::RJR::Nodes::Local.new :node_id => self.user.id
  end

  def node
    Cosmos::RJR.node
  end

  def self.user_registry
    Users::RJR.registry
  end

  def user_registry
    Cosmos::RJR.user_registry
  end

  def self.registry
    @registry ||= Cosmos::Registry.new
  end

  def registry
    Cosmos::RJR.registry
  end

  def self.reset
    Cosmos::RJR.registry.clear!
  end

end # module Cosmos::RJR

######################################## Dispatch init

def dispatch_cosmos_rjr_init(dispatcher)
  # setup Cosmos::RJR module
  rjr = Object.new.extend(Cosmos::RJR)
  rjr.node.dispatcher = dispatcher
  rjr.node.dispatcher.env /cosmos::.*/, Cosmos::RJR
  rjr.node.dispatcher.add_module('cosmos/rjr/create')
  rjr.node.dispatcher.add_module('cosmos/rjr/get')
  rjr.node.dispatcher.add_module('cosmos/rjr/resources')
  rjr.node.dispatcher.add_module('cosmos/rjr/state')
  rjr.node.message_headers['source_node'] = 'cosmos'

  # create cosmos user
  begin rjr.node.invoke('users::create_user', rjr.user)
  rescue Exception => e ; end

  # grant cosmos user extra permissions
  role_id = "user_role_#{rjr.user.id}"
  Cosmos::RJR::PRIVILEGES.each { |p,e|
     rjr.node.invoke('users::add_privilege', role_id, p, e)
   }

  # log the cosmos user in
  session = rjr.node.invoke('users::login', rjr.user)
  rjr.node.message_headers['session_id'] = session.id
end
