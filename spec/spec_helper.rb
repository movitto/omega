# loads and runs all tests for the omega project
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO we currently aren't testing that we
# are logging anything, this needs tbd

################################################################ deps / env

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
require 'omega/client/mixins'

###################################################### rspec / factory girl

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:all) do
    Omega::Config.load.set_config

    # setup a node to dispatch requests
    @n = RJR::Nodes::Local.new :node_id => 'server'

    # setup a node for factory girl
    fgnode = RJR::Nodes::Local.new
    fgnode.dispatcher.add_module('users/rjr/init')
    fgnode.dispatcher.add_module('motel/rjr/init')
    fgnode.dispatcher.add_module('cosmos/rjr/init')
    fgnode.dispatcher.add_module('missions/rjr/init')
    fgnode.dispatcher.add_module('manufactured/rjr/init')
    $fgnode = fgnode # XXX global
    # TODO set current user ?
  end

  # TODO split out a tag for each subsystem so that
  # different dispatchers can be initialized beforehand 
  # and reused by tests in the subsystem (actual registry
  # data will still be cleared with after hook)
  config.before(:each, :rjr => true) do
    # clear/reinit @n
    @n.node_type = RJR::Nodes::Local::RJR_NODE_TYPE
    @n.message_headers = {}
    @n.dispatcher.clear!
    @n.dispatcher.add_module('users/rjr/init')

    # setup a server which to invoke handlers
    # XXX would like to move instantiation into
    # before(:all) hook & just reinit here,
    @s = Object.new
    @s.extend(Omega::Server::DSL)
    @s.instance_variable_set(:@rjr_node, @n)
    set_header 'source_node', @n.node_id
  end

  config.after(:each) do
    # stop centralized registry loops
    registries =
      [Missions::RJR.registry,
       Manufactured::RJR.registry,
       Motel::RJR.registry]
     registries.each { |r| r.stop } # .join ?

     # reset subsystems
     modules =
      [Users::RJR,    Motel::RJR,
       Missions::RJR, Cosmos::RJR,
       Manufactured::RJR]
     modules.each { |m| m.reset }

    # reset client
    Omega::Client::TrackEntity.clear_entities
    Omega::Client::Trackable.node.handlers = nil
    #Omega::Client::Trackable.instance_variable_set(:@handled, nil) # XXX
  end

  config.after(:all) do
  end
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
    before(:create) do |e,i|
      # temporarily disable permission system
      disable_permissions {
        begin $fgnode.invoke(i.create_method, e)
        # assuming operation error just means entity was previously
        # created, and silently ignore
        # (TODO should only rescue OperationError when rjr supports error forwarding)
        rescue Exception => e ; end
      }
    
      e.location.id = e.id if e.respond_to?(:location)
   end 

  end
end

############################################ helper setup & utility methods

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
def setup_manufactured(dispatch_methods=nil, login_user=nil)
  dispatch_to @s, Manufactured::RJR,
                   dispatch_methods  unless dispatch_methods.nil?
  @registry = Manufactured::RJR.registry

  @login_user = login_user.nil? ? create(:user) : login_user
  @login_role = 'user_role_' + @login_user.id
  session_id @s.login(@n, @login_user.id, @login_user.password).id

  # add users, motel, and cosmos modules, initialze manu module
  @n.dispatcher.add_module('motel/rjr/init')
  @n.dispatcher.add_module('cosmos/rjr/init')
  dispatch_manufactured_rjr_init(@n.dispatcher)
end

# Helper to set rjr header
def set_header(header, value)
  @n.message_headers[header] = value
  h = @s.instance_variable_get(:@rjr_headers) || {}
  h[header] = value
  @s.instance_variable_set(:@rjr_headers, h) 
end

# Helper to set session id
def session_id(id)
  id = id.id if id.is_a?(Users::Session)
  set_header 'session_id', id
end

# Helper to wait for notification
#
# XXX local node notifications are processed w/ a thread which
#     notify does not join before returning, need to give thread
#     time to run (come up w/ better way todo this)
def wait_for_notify
  sleep 0.5
end

# Extend session to include a method that forces timeout
module Users
class Session
  def expire!
    @refreshed_time = Time.now - Session::SESSION_EXPIRATION - 100
  end
end
end

###################################################### helper client methods

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

# Helper to reload a superadmin user for client use.
#
# superadmin role entails alot of privileges and
# is used often so continuously recreating w/ add_role
# is slow, this helper speeds things up (~70% faster on avg)
def reload_super_admin
  # XXX global var
  if $sa.nil?
    $sa = create(:user)
    role_id = "user_role_#{$sa.id}"
    add_role role_id, :superadmin
    $sa_role = Users::RJR.registry.entity { |e| e.is_a?(Users::Role) && e.id == role_id }
  else
    Users::RJR.registry << $sa_role
    $sa.roles = [$sa_role]
    Users::RJR.registry << $sa
  end

  $sa
end

# Helper to add attribute to user
def add_attribute(user_id, attribute_id, level)
  disable_permissions {
    @n.invoke 'users::update_attribute', user_id, attribute_id, level
  }
end

######################################################## data / definitions

UUID_PATTERN = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/

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

  class CosmosSystemEntity < CosmosEntity
    include Cosmos::SystemEntity
    VALIDATE_SIZE  = proc { |v| true }
    VALIDATE_COLOR = proc { |v| true }
    RAND_SIZE      = proc { }
    RAND_COLOR     = proc { }
  end
end

##########################################################################
