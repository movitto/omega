# loads and runs all tests for the omega project
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

CURRENT_DIR=File.dirname(__FILE__)
$: << File.expand_path(CURRENT_DIR + "/../lib")

require 'factory_girl'
FactoryGirl.find_definitions

require 'omega/common'
require 'omega/server/config'

require 'users/attribute'
require 'users/session'
require 'users/rjr/init'

require 'motel/movement_strategy'
require 'motel/rjr/init'

require 'missions/rjr/init'

require 'cosmos/rjr/init'

require 'manufactured/rjr/init'

require 'omega/roles'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:all) {
    Omega::Config.load.set_config
  }

  config.before(:each) {
    # setup a node to dispatch requests
    @n = RJR::Nodes::Local.new :node_id => 'server'
    @n.dispatcher.add_module('users/rjr/init')

    # setup a server which to invoke handlers
    @s = Object.new
    @s.extend(Omega::Server::DSL)
    @s.instance_variable_set(:@rjr_node, @n)
    @s.instance_variable_set(:@rjr_headers, {'source_node' => @n.node_id })

    Users::RJR.reset
    Motel::RJR.reset
    Missions::RJR.reset
    Cosmos::RJR.reset
    Manufactured::RJR.reset
  }

  config.after(:each) {
  }

  config.after(:all) {
  }
end

# Build is used to construct entity locally,
# create used to construct on server
FactoryGirl.define do
  trait :server_entity do
    # entities which use this should define the rjr create_method
    ignore do
      create_method nil
    end

    # skip traditonal save! based creation
    skip_create

    # register custom hook to construct the entity serverside
    before(:create) { |e,i|
      if @node.nil?
        @node = RJR::Nodes::Local.new
        @node.dispatcher.add_module('users/rjr/init')
        @node.dispatcher.add_module('motel/rjr/init')
        @node.dispatcher.add_module('cosmos/rjr/init')
        @node.dispatcher.add_module('missions/rjr/init')
        @node.dispatcher.add_module('manufactured/rjr/init')
        # TODO set current user ?
      end

      # temporarily disable permission system
      disable_permissions {
        begin @node.invoke(i.create_method, e)
        # assuming operation error just means entity was previously
        # created, and silently ignore
        # (TODO should only rescue OperationError when rjr supports error forwarding)
        rescue Exception => e ; end
      }
    
      e.location.id = e.id if e.respond_to?(:location)
    }

  end
end

######################################

# Helper method to temporarily disable permission system
def disable_permissions
  o = Users::Registry.user_perms_enabled
  Users::Registry.user_perms_enabled = false
  r = yield
  Users::Registry.user_perms_enabled = o
  r
end

# Helper to enable attribute system
def enable_attributes
  o = Users::RJR.user_attrs_enabled
  Users::RJR.user_attrs_enabled = true
  r = yield
  Users::RJR.user_attrs_enabled = o
  r
end

# Helper method to dispatch server methods to handlers
def dispatch_to(server, rjr_module, dispatcher_id)
  server.extend(rjr_module)
  dispatcher = rjr_module.const_get(dispatcher_id)
  dispatcher.keys.each { |mid|
    server.eigenclass.send(:define_method, mid, &dispatcher[mid])
  }
end

# Helper method to setup manufactured subsystem
def setup_manufactured(dispatch_methods=nil)
  dispatch_to @s, Manufactured::RJR, dispatch_methods unless dispatch_methods.nil?
  @registry = Manufactured::RJR.registry

  @login_user = create(:user)
  @login_role = 'user_role_' + @login_user.id
  @s.login @n, @login_user.id, @login_user.password

  # add users, motel, and cosmos modules, initialze manu module
  @n.dispatcher.add_module('users/rjr/init')
  @n.dispatcher.add_module('motel/rjr/init')
  @n.dispatcher.add_module('cosmos/rjr/init')
  dispatch_manufactured_rjr_init(@n.dispatcher)
end


# Helper to add privilege on entity (optional) 
# to the specified role
def add_privilege(role_id, priv_id, entity_id=nil)
  # change node type to local here to ensure this goes through
  o = @n.node_type
  @n.node_type = RJR::Nodes::Local::RJR_NODE_TYPE
  r = @n.invoke 'users::add_privilege', role_id, priv_id, entity_id
  @n.node_type = o
  r
end

# Helper to add omega role to user role
def add_role(user_role, omega_role)
  # change node type to local here to ensure this goes through
  o = @n.node_type
  @n.node_type = RJR::Nodes::Local::RJR_NODE_TYPE
  r = []
  Omega::Roles::ROLES[omega_role].each { |p,e|
    r << @n.invoke('users::add_privilege', user_role, p, e)
  }
  @n.node_type = o
  r
end

# Helper to add attribute to user
def add_attribute(user_id, attribute_id, level)
  disable_permissions {
    @n.invoke 'users::update_attribute', user_id, attribute_id, level
  }
end

# Helper to set session id
def session_id(id)
  @n.message_headers['session_id'] = id
end

# Extend session to include a method that forces timeout
module Users
class Session
  def expire!
    @refreshed_time = Time.now - Session::SESSION_EXPIRATION - 100
  end
end
end

module OmegaTest
  CLOSE_ENOUGH=0.00001

  class ServerEntity
    attr_accessor :id, :val
    def initialize(args={})
      attr_from_args args, :id => nil, :val => nil
    end

    def to_json(*a)
      { 'json_class' => self.class.name, 'data' => { :id => id, :val => val }}.to_json(*a)
    end

    def self.json_create(o)
      self.new(o['data'])
    end

    def ==(other)
      other.is_a?(ServerEntity) && other.id == id && other.val == val
    end
  end

  class Attribute < Users::AttributeClass
    id :test_attribute
    description 'test attribute description'
    multiplier 5
    callbacks :level_up    => lambda { |attr| @level_up_invoked    = true },
              :level_down  => lambda { |attr| @level_down_invoked  = true },
              :progression => lambda { |attr| @progression_invoked = true },
              :regression  => lambda { |attr| @regression_invoked  = true }
  
    def self.reset_callbacks
      @level_up_invoked    = false
      @level_down_invoked  = false
      @progression_invoked = false
      @regression_invoked  = false
    end
  
    def self.level_up ; @level_up_invoked ; end
    def self.level_down ; @level_down_invoked ; end
    def self.progression ; @progression_invoked ; end
    def self.regression ; @regression_invoked ; end
  end

  class MovementStrategy < Motel::MovementStrategy
     attr_accessor :times_moved
  
     def initialize(args = {})
       @times_moved = 0
       @step_delay = 1
     end
  
     def move(loc, elapsed_time)
       @times_moved += 1
     end
  end

  class CosmosEntity
    include Cosmos::Entity

    PARENT_TYPE = 'CosmosEntity'
    CHILD_TYPES = ['CosmosEntity']

    def initialize(args = {})
      init_entity(args)
    end

    def valid?
      entity_valid?
    end
  end

  class CosmosEnvEntity < CosmosEntity
    include Cosmos::EnvEntity

    NUM_BACKGROUNDS = 5
  end

  class CosmosSystemEntity < CosmosEntity
    include Cosmos::SystemEntity
    VALIDATE_SIZE  = proc { |v| true }
    VALIDATE_COLOR = proc { |v| true }
    RAND_SIZE      = proc { }
    RAND_COLOR     = proc { }
  end
  
  #class Ship
  #  include Omega::Client::Trackable
  #  include Omega::Client::TrackState
  #  include Omega::Client::InSystem
  #  include Omega::Client::HasLocation
  #  include Omega::Client::InteractsWithEnvironment
  #
  #  entity_type Manufactured::Ship
  #  get_method "manufactured::get_entity"
  #
  #  entity_event       :resource_collected => { :subscribe    => "manufactured::subscribe_to",
  #                                              :notification => "manufactured::event_occurred" }
  #
  #  attr_reader :test_setup_args
  #  attr_reader :test_setup_invoked
  #
  #  entity_event :test =>
  #    { :setup =>
  #      lambda { |*args|
  #        @test_setup_args = args
  #        @test_setup_invoked = true
  #      }
  #    }
  #end
  #
  #class Station
  #  include Omega::Client::Trackable
  #  include Omega::Client::TrackState
  #  include Omega::Client::InSystem
  #  include Omega::Client::HasLocation
  #  include Omega::Client::InteractsWithEnvironment
  #
  #  entity_type Manufactured::Station
  #  get_method "manufactured::get_entity"
  #end

end
