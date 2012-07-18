# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'
require 'rjr/local_node'

describe Users::RJRAdapter do

  before(:all) do
    OLD_RECAPTCHA_ENABLED = RECAPTCHA_ENABLED
    RECAPTCHA_ENABLED = false
    Users::RJRAdapter.init
  end

  before(:each) do
    Users::Registry.instance.init
    @local_node = RJR::LocalNode.new :node_id => 'omega-test'
  end

  after(:each) do
  end

  after(:all) do
    RECAPTCHA_ENABLED = OLD_RECAPTCHA_ENABLED
  end

  it "should permit local nodes or users with create users_entities to create_entity" do
    Users::Registry.instance.users.size.should == 0

    nu1 = Users::User.new :id => 'user42'
    nu2 = Users::User.new :id => 'user43'
    u  = TestUser.create.login(@local_node).clear_privileges

    Users::Registry.instance.users.size.should == 1

    # exception for local node needs to be overrided
    @local_node.node_type = 'local-test'

    # insufficient permissions
    lambda{
      @local_node.invoke_request('users::create_entity', nu1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('create', 'users_entities')

    # invalid entity
    lambda{
      @local_node.invoke_request('users::create_entity', 123)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      ru = @local_node.invoke_request('users::create_entity', nu1)
      ru.class.should == Users::User
      ru.id.should == nu1.id
    }.should_not raise_error

    # invalid entity (duplicate id)
    lambda{
      @local_node.invoke_request('users::create_entity', nu1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    Users::Registry.instance.users.size.should == 2

    u.clear_privileges

    @local_node.node_type = :local

    # valid call
    lambda{
      ru = @local_node.invoke_request('users::create_entity', nu2)
      ru.class.should == Users::User
      ru.id.should == nu2.id
    }.should_not raise_error

    Users::Registry.instance.users.size.should == 3
  end

  it "should permit users with view users_entities or view user_entity-<id> to get_entity" do
    nu = Users::User.new :id => 'user43'
    u  = TestUser.create.login(@local_node).clear_privileges

    Users::Registry.instance.create nu
    Users::Registry.instance.users.size.should == 2

    # insufficient permissions
    lambda{
      @local_node.invoke_request('users::get_entity', 'with_id', nu.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('view', 'users_entities')

    # invalid entity id
    lambda{
      ru = @local_node.invoke_request('users::get_entity', 'with_id', 'invalid')
    # }.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid qualifier
    lambda{
      ru = @local_node.invoke_request('users::get_entity', 'invalid', nu.id)
    # }.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      ru = @local_node.invoke_request('users::get_entity', 'with_id', nu.id)
      ru.class.should == Users::User
      ru.id.should == nu.id
    }.should_not raise_error

    u.clear_privileges.add_privilege('view', 'users_entity-' + nu.id)

    # valid call
    lambda{
      ru = @local_node.invoke_request('users::get_entity', 'with_id', nu.id)
      ru.class.should == Users::User
      ru.id.should == nu.id
    }.should_not raise_error

    u.clear_privileges.add_privilege('view', 'users_entity-foobar')

    # insufficient permissions
    lambda{
      @local_node.invoke_request('users::get_entity', 'with_id', nu.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)
  end

  it "should permit users with view users_entities to get_all_entities" do
    nu1 = Users::User.new :id => 'user43'
    nu2 = Users::User.new :id => 'user44'
    a1  = Users::Alliance.new :id => 'alliance52'
    u  = TestUser.create.login(@local_node).clear_privileges

    Users::Registry.instance.create nu1
    Users::Registry.instance.create nu2
    Users::Registry.instance.create a1
    Users::Registry.instance.users.size.should == 3
    Users::Registry.instance.alliances.size.should == 1

    lambda{
      rus = @local_node.invoke_request('users::get_entities')
      rus.class.should == Array
      rus.empty?.should be_true
    }.should_not raise_error

    u.add_privilege('view', 'users_entities')

    lambda{
      rus = @local_node.invoke_request('users::get_entities')
      rus.class.should == Array
      rus.size.should == 4
      rus.collect { |ru| ru.id }.should include(nu1.id)
      rus.collect { |ru| ru.id }.should include(nu2.id)
      rus.collect { |ru| ru.id }.should include(a1.id)
    }.should_not raise_error
  end

  it "should permit users with view users_entities to get_entities by type" do
    nu1 = Users::User.new :id => 'user43'
    nu2 = Users::User.new :id => 'user44'
    a1  = Users::Alliance.new :id => 'alliance52'
    u  = TestUser.create.login(@local_node).clear_privileges.add_privilege('view', 'users_entities')

    Users::Registry.instance.create nu1
    Users::Registry.instance.create nu2
    Users::Registry.instance.create a1

    lambda{
      rus = @local_node.invoke_request('users::get_entities', 'of_type', "Users::Alliance")
      rus.class.should == Array
      rus.size.should == 1
      rus.collect { |ru| ru.id }.should include(a1.id)
    }.should_not raise_error

    lambda{
      rus = @local_node.invoke_request('users::get_entities', 'of_type', "Users::User")
      rus.class.should == Array
      rus.size.should == 3
      rus.collect { |ru| ru.id }.should include(nu1.id)
      rus.collect { |ru| ru.id }.should include(nu2.id)
    }.should_not raise_error
  end

  # TODO
  # send_message
  # subscribe_to_messages

  it "should permit a user with valid credentials to login and logout" do
    nu1 = Users::User.new :id => 'user44', :password => 'foobar'
    u  = TestUser.create.login(@local_node).clear_privileges

    Users::Registry.instance.create nu1
    Users::Registry.instance.users.size.should == 2

    lu = Users::User.new :id => 'non_existant', :password => 'incorrect'

    # not a user
    lambda{
      @local_node.invoke_request('users::login', 'lu')
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid user id
    lambda{
      @local_node.invoke_request('users::login', lu)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lu.id = 'user44'

    # invalid password
    lambda{
      @local_node.invoke_request('users::login', lu)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    lu.password = 'foobar'

    # valid call
    session = nil
    lambda{
      session = @local_node.invoke_request('users::login', lu)
      session.class.should == Users::Session
      session.user_id.should == nu1.id
    }.should_not raise_error

    Users::Registry.instance.sessions.size.should == 2

    # invalid session
    lambda{
      @local_node.invoke_request('users::logout', 'session.id')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      @local_node.invoke_request('users::logout', session.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'user-' + nu1.id)

    # valid call
    lambda{
      ret = @local_node.invoke_request('users::logout', session.id)
      ret.should be_nil
    }.should_not raise_error

    Users::Registry.instance.sessions.size.should == 1
    Users::Registry.instance.sessions.find { |s| s.id == session.id }.should be_nil
  end
  
  it "should permit the local node or users with modify users_entities to add_privilege" do
    nu = Users::User.new :id => 'user43'
    u  = TestUser.create.login(@local_node).clear_privileges

    Users::Registry.instance.create nu
    Users::Registry.instance.users.size.should == 2

    # exception for local node needs to be overrided
    @local_node.node_type = 'local-test'

    # insufficient permissions
    lambda{
      @local_node.invoke_request('users::add_privilege', nu.id, 'view', 'all')
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'users_entities')

    # invalid user
    lambda{
      @local_node.invoke_request('users::add_privilege', 'non_existant', 'view', 'all')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # valid call
    lambda{
      ret = @local_node.invoke_request('users::add_privilege', nu.id, 'view', 'all')
      ret.should be_nil
    }.should_not raise_error

    u.clear_privileges

    @local_node.node_type = :local

    # valid call
    lambda{
      @local_node.invoke_request('users::add_privilege', nu.id, 'modify', 'all')
    }.should_not raise_error

    # duplicate call (no error, but no effect)
    lambda{
      @local_node.invoke_request('users::add_privilege', nu.id, 'modify', 'all')
    }.should_not raise_error

    nu.privileges.size.should == 2
    nu.privileges.first.id.should == 'view'
    nu.privileges.first.entity_id.should == 'all'
    nu.privileges.last.id.should == 'modify'
    nu.privileges.last.entity_id.should == 'all'
  end

  it "should permit a valid user to register and confirm their registration" do
    nu1 = Users::User.new :id => 'user43', :password => 'foobar', :email => 'invalid'
    u  = TestUser.create.login(@local_node).clear_privileges

    Users::Registry.instance.users.size.should == 1

    # not a user instance
    lambda{
      @local_node.invoke_request('users::register', "nu1")
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid email
    lambda{
      @local_node.invoke_request('users::register', nu1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    nu1.email = 'now@val.id'
    nu1.id = 'omega-test'

    # duplicate user
    lambda{
      @local_node.invoke_request('users::register', nu1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    nu1.id = 'user43'
    nu1.password = nil

    # invalid password
    lambda{
      @local_node.invoke_request('users::register', nu1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    nu1.password = 'foobar'

    # valid calls
    lambda{
      ru = @local_node.invoke_request('users::register', nu1)
      ru.class.should == Users::User
      ru.id.should == nu1.id
      ru.registration_code.should_not be_nil
      rc = ru.registration_code

      du = Users::Registry.instance.users.find { |u| u.id == nu1.id }
      du.should_not be_nil
      du.registration_code.should == rc
      du.alliances.empty?.should be_true
      du.privileges.empty?.should be_true

      ret = @local_node.invoke_request('users::confirm_register', rc)
      ret.should be_nil
    }.should_not raise_error

    Users::Registry.instance.users.size.should == 2
  end

  it "should permit a user with modify users_entities to update_user" do
    nu1 = Users::User.new :id => 'user43', :password => 'foobar'
    u  = TestUser.create.login(@local_node).clear_privileges

    Users::Registry.instance.create nu1
    Users::Registry.instance.users.size.should == 2

    uu = Users::User.new :id => 'non_existant', :password => 'foozbar'

    # not a user
    lambda{
      @local_node.invoke_request('users::update_user', 'uu')
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid user id
    lambda{
      @local_node.invoke_request('users::update_user', uu)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)
    
    uu.id = 'user43'

    # insufficient permissions
    lambda{
      @local_node.invoke_request('users::update_user', uu)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'users')

    # valid call
    lambda{
      ru = @local_node.invoke_request('users::update_user', uu)
      ru.class.should == Users::User
      ru.id.should == nu1.id
    }.should_not raise_error

    nu1.password.should == 'foozbar'
  end

  it "should permit local nodes to save and restore state" do
    nu1 = Users::User.new :id => 'user43'
    nu2 = Users::User.new :id => 'user44'
    u  = TestUser.create.login(@local_node).clear_privileges

    Users::Registry.instance.create nu1
    Users::Registry.instance.create nu2
    Users::Registry.instance.users.size.should == 3

    lambda{
      ret = @local_node.invoke_request('users::save_state', '/tmp/users-test')
      ret.should be_nil
    }.should_not raise_error

    Users::Registry.instance.init
    Users::Registry.instance.users.size.should == 0

    lambda{
      ret = @local_node.invoke_request('users::restore_state', '/tmp/users-test')
      ret.should be_nil
    }.should_not raise_error

    Users::Registry.instance.users.size.should == 3
    Users::Registry.instance.users.last.id.should == nu2.id

    FileUtils.rm_f '/tmp/users-test'
  end
end
