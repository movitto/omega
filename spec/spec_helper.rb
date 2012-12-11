# loads and runs all tests for the motel project
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'factory_girl'
require 'omega/client2/mixins'

CURRENT_DIR=File.dirname(__FILE__)
$: << File.expand_path(CURRENT_DIR + "/../lib")

CLOSE_ENOUGH=0.000001

require 'motel'
require 'cosmos'
require 'manufactured'
require 'users'
require 'omega'

FactoryGirl.find_definitions

class TestMovementStrategy < Motel::MovementStrategy
   attr_accessor :times_moved

   def initialize(args = {})
     @times_moved = 0
     @step_delay = 1
   end

   def move(loc, elapsed_time)
     @times_moved += 1
   end
end

class TestUser
  # always call me first!
  def self.create
    @@user ||= Users::User.new :id => 'omega-test', :password => 'tset-agemo'
    @@session ||= nil
    self.logout unless @@session.nil?
    Users::Registry.instance.create @@user
    self
  end

  def self.id
    @@user.id
  end

  def self.password
    @@user.password
  end

  def self.privileges
    @@user.privileges
  end

  def self.login(node = nil)
    self.logout unless @@session.nil?
    @@session = Users::Registry.instance.create_session(@@user)
    node.message_headers['session_id'] = @@session.id unless node.nil?
    self
  end

  def self.logout
    unless @@session.nil?
      Users::Registry.instance.destroy_session(:session_id => @@session.id)
      @@session = nil
    end
    self
  end

  def self.clear_privileges
    self.clear_roles
    self
  end

  def self.clear_roles
    @@user.clear_roles
    self
  end

  def self.add_privilege(privilege_id, entity_id = nil)
    self.create_user_role
    @@user.roles.first.add_privilege Users::Privilege.new(:id => privilege_id, :entity_id => entity_id)
    self
  end

  def self.create_user_role
    self.add_role("user_role_#{@@user.id}") if @@user.roles.empty?
    self
  end

  def self.add_role(role_id)
    role = Users::Role.new(:id => role_id)
    @@user.add_role role
    Users::Registry.instance.create role
    self
  end

  def self.add_omega_role(role_id)
    permissions = Omega::Roles::ROLES[role_id]
    self.add_role(role_id)
    permissions.each { |pe|
      self.add_privilege pe[0], pe[1]
    }
    self
  end
end

class TestEntity
  include Omega::Client::RemotelyTrackable
  include Omega::Client::TrackState
  entity_type Manufactured::Ship
  get_method "manufactured::get_entity"

  server_state :test_state,
    { :check => lambda { |e| @toggled ||= false ; @toggled = !@toggled },
      :on    => lambda { |e| @on_toggles_called  = true },
      :off   => lambda { |e| @off_toggles_called = true } }

  def initialize
    @@id ||= 0
    @id = (@@id +=  1)
  end

  def id
    @id
  end

  def attr
    0
  end

  def location(val = nil)
    @location = val unless val.nil?
    @location
  end
end

class TestShip
  include Omega::Client::RemotelyTrackable
  include Omega::Client::TrackState
  include Omega::Client::InSystem
  include Omega::Client::HasLocation
  include Omega::Client::InteractsWithEnvironment

  entity_type Manufactured::Ship
  get_method "manufactured::get_entity"

  attr_reader :test_setup_args
  attr_reader :test_setup_invoked

  server_event :test =>
    { :setup =>
      lambda { |*args|
        @test_setup_args = args
        @test_setup_invoked = true
      }
    }
end

class TestStation
  include Omega::Client::RemotelyTrackable
  include Omega::Client::TrackState
  include Omega::Client::InSystem
  include Omega::Client::HasLocation
  include Omega::Client::InteractsWithEnvironment

  entity_type Manufactured::Station
  get_method "manufactured::get_entity"
end
