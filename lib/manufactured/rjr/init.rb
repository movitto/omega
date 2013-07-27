# Initialize the manufactured subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

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
     ['create', 'manufactured_entities']]

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

  ######################################## Callback methods

  # callback to track_movement and track_rotation in move_entity
  motel_event = proc { |loc|
    raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)

    # retrieve registry entity / location
    entity = registry.entity { |e| e.is_a?(Ship) && e.location.id == loc.id }
    unless entity.nil?
      oloc = entity.location

      # update user attributes
      if(oloc.movement_strategy.is_a?(Motel::MovementStrategies::Linear))
        node.invoke('users::update_attribute', entity.user_id,
                    Users::Attributes::DistanceTravelled.id,
                    entity.distance_moved)
        entity.distance_moved = 0
      end

      # update movement strategy
      old = loc.movement_strategy
      stopped = Motel::MovementStrategies::Stopped.instance
      loc.movement_strategy =
        loc.next_movement_strategy || stopped
      loc.next_movement_strategy = stopped
    
      # update location
      node.invoke('motel::update_location', loc)
    
      # remove callbacks if changing movement strategy
      if old != loc.movement_strategy
        if old.is_a?(Motel::MovementStrategies::Linear)
          node.invoke('motel::remove_callbacks', loc.id, :movement)
        elsif old.is_a?(Motel::MovementStrategies::Rotate)
          node.invoke('motel::remove_callbacks', loc.id, :rotation)
        end
      end

      # update the entity in the registry
      registry.update(entity, &with_id(entity.id))
    end

    nil
  }

  CALLBACK_METHODS = { :motel_event => motel_event }

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
  rjr.node.dispatcher.add_module('manufactured/rjr/get')
  rjr.node.dispatcher.add_module('manufactured/rjr/state')
  rjr.node.dispatcher.add_module('manufactured/rjr/events')
  rjr.node.dispatcher.add_module('manufactured/rjr/resources')
  rjr.node.dispatcher.add_module('manufactured/rjr/movement')
  rjr.node.dispatcher.add_module('manufactured/rjr/dock')
  rjr.node.dispatcher.add_module('manufactured/rjr/mining')
  rjr.node.dispatcher.add_module('manufactured/rjr/attack')
  rjr.node.dispatcher.add_module('manufactured/rjr/loot')
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

  # add callback for motel events, override environment it runs in
  m = Manufactured::RJR::CALLBACK_METHODS
  rjr.node.dispatcher.handle(['motel::on_movement', 'motel::on_rotation'],
                             &m[:motel_event])
  rjr.node.dispatcher.env ['motel::on_movement', 'motel::on_rotation'],
                          Manufactured::RJR
end
