# loads and runs all tests for the motel project
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'

CURRENT_DIR=File.dirname(__FILE__)
$: << File.expand_path(CURRENT_DIR + "/../lib")

CLOSE_ENOUGH=0.000001

require 'motel'
require 'cosmos'
require 'manufactured'
require 'users'
require 'omega'

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
    @@user ||= Users::User.new :id => 'omega-test'
    @@session ||= nil
    self.logout unless @@session.nil?
    Users::Registry.instance.create @@user
    self
  end

  def self.id
    @@user.id
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
    @@user.clear_privileges
    self
  end

  def self.add_privilege(privilege_id, entity_id = nil)
    @@user.add_privilege Users::Privilege.new(:id => privilege_id, :entity_id => entity_id)
    self
  end

  def self.add_role(role_id)
    role = Omega::Roles::ROLES[role_id]
    role.each { |pe|
      self.add_privilege pe[0], pe[1]
    }
    self
  end

end
