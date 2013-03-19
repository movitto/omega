# loads and runs all tests for the omega project
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'factory_girl'

CURRENT_DIR=File.dirname(__FILE__)
$: << File.expand_path(CURRENT_DIR + "/../lib")

CLOSE_ENOUGH=0.000001

require 'motel'
require 'cosmos'
require 'manufactured'
require 'users'
require 'missions'
require 'omega'

FactoryGirl.find_definitions

RSpec.configure do |config|
  config.before(:all) {
    Omega::Config.load.set_config
  }
  config.before(:each) {
    Motel::RJRAdapter.init
    Users::RJRAdapter.init
    Cosmos::RJRAdapter.init
    Manufactured::RJRAdapter.init
    Missions::RJRAdapter.init

    TestUser.create.clear_privileges

    Omega::Client::Node.client_username = 'omega-test'
    Omega::Client::Node.client_password = 'tset-agemo'
    Omega::Client::Node.node = RJR::LocalNode.new :node_id => 'omega-test'

    Omega::Client::CachedAttribute.clear
    Omega::Client::Node.clear

    # preload all server entities
    FactoryGirl.factories.each { |k,v|
      p = k.instance_variable_get(:@parent)
      FactoryGirl.build(k.name) if p =~ /server_.*/
    }
  }

  config.after(:each) {
    Omega::Client::CachedAttribute.clear
    Omega::Client::Node.clear
    Missions::Registry.instance.init
    Manufactured::Registry.instance.init
    Cosmos::Registry.instance.init
    Motel::Runner.instance.clear
    Users::Registry.instance.init
  }
  config.after(:all) {
  }
end

class TestUser
  def self.create
    @@test_user = FactoryGirl.build(:test_user)
    return self
  end

  def self.clear_privileges
    @@test_user.roles.first.clear_privileges
    return self
  end

  def self.add_privilege(privilege_id, entity_id = nil)
    @@test_user.roles.first.add_privilege \
      Users::Privilege.new(:id => privilege_id, :entity_id => entity_id)
    return self
  end

  def self.add_role(role_id)
    Omega::Roles::ROLES[role_id].each { |pe|
      self.add_privilege pe[0], pe[1]
    }
    return self
  end

  def self.method_missing(method, *args, &bl)
    @@test_user.send(method, *args, &bl)
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

  server_event       :resource_collected => { :subscribe    => "manufactured::subscribe_to",
                                              :notification => "manufactured::event_occurred" }

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

####################################################

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

####################################################

class TestAttribute < Users::AttributeClass
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
