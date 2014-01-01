# Initialize the missions subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'missions/registry'
require 'omega/exceptions'
require 'omega/server/dsl'
require 'users/rjr/init'

# require mission event types
require 'missions/events/resources'
require 'missions/events/manufactured'
require 'missions/events/users'

module Missions::RJR
  include Omega#::Exceptions
  include Missions
  include Omega::Server::DSL

  ######################################## Config

  class << self
    # @!group Config options

    # User to use to communicate w/ other modules over the local rjr node
    attr_accessor :missions_rjr_username

    # Password to use to communicate w/ other modules over the local rjr node
    attr_accessor :missions_rjr_password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.missions_rjr_username  = config.missions_rjr_user
      self.missions_rjr_password  = config.missions_rjr_pass
    end

    # @!endgroup
  end

  ######################################## Missions::RJR data

  PRIVILEGES =
    [['view',   'users'],
     ['modify', 'user_attributes'],
     ['view',   'users_events'],
     ['view',   'cosmos_entities'],
     ['modify', 'cosmos_entities'],
     ['create', 'cosmos_entities'],
     ['view',   'manufactured_entities'],
     ['create', 'manufactured_entities'],
     ['modify', 'manufactured_entities'],
     ['modify', 'manufactured_resources'],
     ['create', 'missions']]

  def self.user
    @user ||= Users::User.new(:id       => Missions::RJR::missions_rjr_username,
                              :password => Missions::RJR::missions_rjr_password,
                              :registration_code => nil)
  end

  def user
    Missions::RJR.user
  end

  def self.node
    @node ||= ::RJR::Nodes::Local.new :node_id => self.user.id
  end

  def node
    Missions::RJR.node
  end

  def self.user_registry
    Users::RJR.registry
  end

  def user_registry
    Missions::RJR.user_registry
  end

  def self.registry
    @registry ||= Missions::Registry.new
  end

  def registry
    Missions::RJR.registry
  end

  def self.reset
    Missions::RJR.registry.clear!
  end

  ######################################## Callback methods

  manufactured_event = proc { |*args|
    raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)

    event = Missions::Events::Manufactured.new *args
    registry << event
    nil
  }

  users_event = proc { |*args|
    raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)

    event = Missions::Events::Users.new :users_event_args => args
    registry << event
    nil
  }

  CALLBACK_METHODS = { :manufactured_event => manufactured_event,
                       :users_event        => users_event       }

end # module Missions::RJR

######################################## Dispatch init

def dispatch_missions_rjr_init(dispatcher)
  Missions::RJR.registry.start

  # setup Missions::RJR module
  rjr = Object.new.extend(Missions::RJR)
  rjr.node.dispatcher = dispatcher
  rjr.node.dispatcher.env /missions::.*/, Missions::RJR
  rjr.node.dispatcher.add_module('missions/rjr/create')
  rjr.node.dispatcher.add_module('missions/rjr/get')
  rjr.node.dispatcher.add_module('missions/rjr/assign')
  rjr.node.dispatcher.add_module('missions/rjr/hooks')
  rjr.node.dispatcher.add_module('missions/rjr/state')
  rjr.node.message_headers['source_node'] = 'missions'

  # create missions user
  begin rjr.node.invoke('users::create_user', rjr.user)
  rescue Exception => e ; end

  # grant missions user extra permissions
  # all in all missions is a pretty powerful role/user in terms
  #  of what it can do w/ the simulation
  role_id = "user_role_#{rjr.user.id}"
  Missions::RJR::PRIVILEGES.each { |p,e|
     rjr.node.invoke('users::add_privilege', role_id, p, e)
   }

  # log the missions user in
  session = rjr.node.invoke('users::login', rjr.user)
  rjr.node.message_headers['session_id'] = session.id

  # add callback for manufactured events, override environment it runs in
  m = Missions::RJR::CALLBACK_METHODS
  rjr.node.dispatcher.handle('manufactured::event_occurred', &m[:manufactured_event])
  rjr.node.dispatcher.env 'manufactured::event_occurred', Missions::RJR

  # add callback for users events, subscribe to registered_user event
  rjr.node.dispatcher.handle('users::event_occurred', &m[:users_event])
  rjr.node.dispatcher.env 'users::event_occurred', Missions::RJR
  rjr.node.invoke('users::subscribe_to', 'registered_user')
end
