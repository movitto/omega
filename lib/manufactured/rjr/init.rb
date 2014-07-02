# Initialize the manufactured subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'manufactured/registry'
require 'omega/exceptions'
require 'omega/server/dsl'
require 'users/rjr/init'

require 'motel/movement_strategies/linear'
require 'motel/movement_strategies/stopped'

module Manufactured::RJR
  include Omega#::Exceptions
  include Manufactured
  include Omega::Server::DSL

  ######################################## Config

  class << self
    # @!group Config options

    # User to use to communicate w/ other modules over the local rjr node
    attr_accessor :manufactured_rjr_username

    # Password to use to communicate w/ other modules over the local rjr node
    attr_accessor :manufactured_rjr_password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.manufactured_rjr_username  = config.manufactured_rjr_user
      self.manufactured_rjr_password  = config.manufactured_rjr_pass
    end

    # @!endgroup
  end

  ######################################## Manufactured::RJR data

  PRIVILEGES =
    [['view',   'cosmos_entities'],
     ['modify', 'cosmos_entities'],
     ['view',   'users'          ],
     ['view',   'user_attributes'],
     ['modify', 'user_attributes'],
     ['create', 'locations'      ],
     ['view',   'locations'      ],
     ['modify', 'locations'      ],
     ['delete', 'locations'      ],
     ['create', 'manufactured_entities']]

  # Helper method to generate the permissions granted
  # to the owner of a manufactured entity upon creation
  def owner_permissions_for(entity)
    entity_id   = entity.id
    location_id = entity.location.id

    [["view",   "manufactured_entity-#{entity_id}"],
     ['modify', "manufactured_entity-#{entity_id}"],
     ['view',            "location-#{location_id}"]]
  end

  def self.user
    @user ||= Users::User.new(:id       => Manufactured::RJR::manufactured_rjr_username,
                              :password => Manufactured::RJR::manufactured_rjr_password,
                              :registration_code => nil)
  end

  def user
    Manufactured::RJR.user
  end

  def self.node
    @node ||= ::RJR::Nodes::Local.new :node_id => self.user.id
  end

  def node
    Manufactured::RJR.node
  end

  def self.user_registry
    Users::RJR.registry
  end

  def user_registry
    Manufactured::RJR.user_registry
  end

  def self.registry
    @registry ||= Manufactured::Registry.new
  end

  def registry
    Manufactured::RJR.registry
  end

  def self.reset
    Manufactured::RJR.registry.clear!
  end
end # module Manufactured::RJR

######################################## Dispatch init

def dispatch_manufactured_rjr_init(dispatcher)
  Manufactured::RJR.registry.start
  Manufactured::RJR.registry.node = Manufactured::RJR.node

  # setup Manufactured::RJR module
  rjr = Object.new.extend(Manufactured::RJR)
  rjr.node.dispatcher = dispatcher
  rjr.node.dispatcher.env /manufactured::.*/, Manufactured::RJR
  rjr.node.dispatcher.add_module('manufactured/rjr/create')
  rjr.node.dispatcher.add_module('manufactured/rjr/construct')
  rjr.node.dispatcher.add_module('manufactured/rjr/validate')
  rjr.node.dispatcher.add_module('manufactured/rjr/get')
  rjr.node.dispatcher.add_module('manufactured/rjr/state')
  rjr.node.dispatcher.add_module('manufactured/rjr/subscribe_to')
  rjr.node.dispatcher.add_module('manufactured/rjr/remove_callbacks')
  rjr.node.dispatcher.add_module('manufactured/rjr/resources')
  rjr.node.dispatcher.add_module('manufactured/rjr/move')
  rjr.node.dispatcher.add_module('manufactured/rjr/follow')
  rjr.node.dispatcher.add_module('manufactured/rjr/stop')
  rjr.node.dispatcher.add_module('manufactured/rjr/dock')
  rjr.node.dispatcher.add_module('manufactured/rjr/mining')
  rjr.node.dispatcher.add_module('manufactured/rjr/attack')
  rjr.node.dispatcher.add_module('manufactured/rjr/loot')
  rjr.node.dispatcher.add_module('manufactured/rjr/motel_callback')
  rjr.node.message_headers['source_node'] = 'manufactured'

  # create manufactured user
  begin rjr.node.invoke('users::create_user', rjr.user)
  rescue Exception => e ; end

  # grant manufactured user extra permanufactured
  role_id = "user_role_#{rjr.user.id}"
  Manufactured::RJR::PRIVILEGES.each { |p,e|
     rjr.node.invoke('users::add_privilege', role_id, p, e)
   }

  # log the manufactured user in
  session = rjr.node.invoke('users::login', rjr.user)
  rjr.node.message_headers['session_id'] = session.id
end
