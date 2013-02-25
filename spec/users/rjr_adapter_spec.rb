# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/local_node'

describe Users::RJRAdapter do

  before(:all) do
    Users::EmailHelper.email_enabled = false
    Users::RJRAdapter.recaptcha_enabled = false
    Users::RJRAdapter.permenant_users = ['admin', 'rjr-perm-user-test']
  end

  it "should permit local nodes or users with create users_entities to create_entity" do
    old = Users::Registry.instance.users.size

    nu1 = Users::User.new :id => 'user42', :password => 'foobar'
    nu2 = Users::User.new :id => 'user43', :password => 'foobar'

    # exception for local node needs to be overrided
    Omega::Client::Node.node_type = 'local-test'

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('users::create_entity', nu1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('create', 'users_entities')

    # invalid entity
    lambda{
      Omega::Client::Node.invoke_request('users::create_entity', 123)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      ru = Omega::Client::Node.invoke_request('users::create_entity', nu1)
      ru.class.should == Users::User
      ru.id.should == nu1.id
      ru.password.should be_nil # ensure pass returned by server is nil
    }.should_not raise_error

    # invalid entity (duplicate id)
    lambda{
      Omega::Client::Node.invoke_request('users::create_entity', nu1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    Users::Registry.instance.users.size.should == old + 1

    TestUser.clear_privileges

    Omega::Client::Node.node_type = :local

    # valid call
    lambda{
      ru = Omega::Client::Node.invoke_request('users::create_entity', nu2)
      ru.class.should == Users::User
      ru.id.should == nu2.id
    }.should_not raise_error

    Users::Registry.instance.users.size.should == old + 2

    # ensure
    #  -secure_password is set to true
    #  -user has view & modify privs on self
    #  -pass is encrypted on create_entity
    #  -role is created for user, and it is assigned to user
    [Users::Registry.instance.find(:id => nu2.id).first,
     Users::Registry.instance.find(:id => nu1.id).first].each { |u|
      TestUser.secure_password.should be_true
      u.privileges.find { |p| p.id == 'view'   && p.entity_id == "users_entity-#{u.id}" }.should_not be_nil
      u.privileges.find { |p| p.id == 'modify' && p.entity_id == "users_entity-#{u.id}" }.should_not be_nil
      u.password.should_not == "foobar"
      PasswordHelper.check("foobar", u.password).should be_true

      r = Users::Registry.instance.roles.find { |r| r.id == "user_role_#{u.id}" }
      r.should_not be_nil
      u.roles.should include(r)
    }
  end

  it "should mark new users in the permenant_users list as permenant" do
    old = Users::Registry.instance.users.size
    nu1 = Users::User.new :id => 'rjr-perm-user-test', :password => 'foobar'

    lambda{
      ru = Omega::Client::Node.invoke_request('users::create_entity', nu1)
    }.should_not raise_error

    Users::Registry.instance.users.size.should == old + 1
    Users::Registry.instance.users.last.permenant.should == true
  end

  it "should permit users with view users_entities or view user_entity-<id> to get_entity" do
    old = Users::Registry.instance.users.size

    nu = Users::User.new :id => 'user43'
    Users::Registry.instance.create nu
    Users::Registry.instance.users.size.should == old + 1

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('users::get_entity', 'with_id', nu.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('view', 'users_entities')

    # invalid entity id
    lambda{
      ru = Omega::Client::Node.invoke_request('users::get_entity', 'with_id', 'invalid')
    # }.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid qualifier
    lambda{
      ru = Omega::Client::Node.invoke_request('users::get_entity', 'invalid', nu.id)
    # }.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # valid call
    lambda{
      ru = Omega::Client::Node.invoke_request('users::get_entity', 'with_id', nu.id)
      ru.class.should == Users::User
      ru.id.should == nu.id
      ru.password.should be_nil # ensure pass returned by server is nil
    }.should_not raise_error

    TestUser.clear_privileges.add_privilege('view', 'users_entity-' + nu.id)

    # valid call
    lambda{
      ru = Omega::Client::Node.invoke_request('users::get_entity', 'with_id', nu.id)
      ru.class.should == Users::User
      ru.id.should == nu.id
    }.should_not raise_error

    TestUser.clear_privileges.add_privilege('view', 'users_entity-foobar')

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('users::get_entity', 'with_id', nu.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)
  end

  it "should permit users with view users_entities to get_all_entities" do
    nu1 = Users::User.new :id => 'user43'
    nu2 = Users::User.new :id => 'user44'
    a1  = Users::Alliance.new :id => 'alliance52'

    Users::Registry.instance.create nu1
    Users::Registry.instance.create nu2
    Users::Registry.instance.create a1

    numu = Users::Registry.instance.users.size
    numr = Users::Registry.instance.roles.size
    numa = Users::Registry.instance.alliances.size

    lambda{
      rus = Omega::Client::Node.invoke_request('users::get_entities')
      rus.class.should == Array
      rus.empty?.should be_true
    }.should_not raise_error

    TestUser.add_privilege('view', 'users_entities')

    lambda{
      rus = Omega::Client::Node.invoke_request('users::get_entities')
      rus.class.should == Array
      rus.size.should == numu + numr + numa
      rus.collect { |ru| ru.id }.should include(nu1.id)
      rus.collect { |ru| ru.id }.should include(nu2.id)
      rus.collect { |ru| ru.id }.should include(a1.id)
    }.should_not raise_error
  end

  it "should permit users with view users_entities to get_entities by type" do
    nu1 = Users::User.new :id => 'user43'
    nu2 = Users::User.new :id => 'user44'
    a1  = Users::Alliance.new :id => 'alliance52'

    TestUser.add_privilege('view', 'users_entities')

    Users::Registry.instance.create nu1
    Users::Registry.instance.create nu2
    Users::Registry.instance.create a1

    numu = Users::Registry.instance.users.size

    lambda{
      rus = Omega::Client::Node.invoke_request('users::get_entities', 'of_type', "Users::Alliance")
      rus.class.should == Array
      rus.size.should == 1
      rus.collect { |ru| ru.id }.should include(a1.id)
    }.should_not raise_error

    rus = nil
    lambda{
      rus = Omega::Client::Node.invoke_request('users::get_entities', 'of_type', "Users::User")
    }.should_not raise_error

    rus.class.should == Array
    rus.size.should == numu
    ru = rus.find { |ru| ru.id == nu1.id }
    ru.should_not be_nil
    ru.password.should be_nil  # ensure pass returned by server is nil

    ru = rus.find { |ru| ru.id == nu2.id }
    ru.should_not be_nil
    ru.password.should be_nil
  end

  # send_message
  it "should permit a user with modify users to send chat message" do
    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('users::send_message', 'send-test-message')
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'users')

    lambda{
      Omega::Client::Node.invoke_request('users::send_message', 'send-test-message')
    }.should_not raise_error

    Users::ChatProxy.proxy_for(TestUser.id).messages.should include("send-test-message")
  end

  #  TODO does chat proxy for TestUser actual work?
  # subscribe_to_messages
  #it "should permit a user with view user_entities to receive message" do
  #  proxy1 = Users::ChatProxy.proxy_for 'rjrusetes'
  #  proxy1.connect
  #  sleep 3 until proxy1.connected && proxy1.inchannel

  #  invoked = false
  #  RJR::Dispatcher.add_handler("users::on_message") { |msg|
  #    msg.nick.should == "rjrusetes"
  #    msg.message.should == "receive-test-message"
  #    invoked = true
  #  }

  #  # insufficient permissions
  #  lambda{
  #    Omega::Client::Node.invoke_request('users::subscribe_to_messages')
  #  #}.should raise_error(Omega::PermissionError)
  #  }.should raise_error(Exception)

  #  TestUser.add_privilege('view', 'users_entities')

  #  lambda{
  #    Omega::Client::Node.invoke_request('users::subscribe_to_messages')
  #  }.should_not raise_error

  #  proxy1.proxy_message('receive-test-message')
  #  invoked.should be_true
  #end

  # get_messages
  it "should permit a user with view user_entities to get message" do
    Users::ChatProxy.proxy_for(TestUser.id).messages << "test-message"

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('users::get_messages')
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('view', 'users_entities')

    lambda{
      messages = Omega::Client::Node.invoke_request('users::get_messages')
      messages.should include("test-message")
    }.should_not raise_error
  end

  it "should permit a user with valid credentials to login and logout" do
    nu1 = Users::User.new :id => 'user44', :password => 'foobar'
    lu = Users::User.new :id => 'non_existant', :password => 'incorrect'
    Users::Registry.instance.create nu1

    # not a user
    lambda{
      Omega::Client::Node.invoke_request('users::login', 'lu')
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid user id
    lambda{
      Omega::Client::Node.invoke_request('users::login', lu)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lu.id = 'user44'

    # invalid password
    lambda{
      Omega::Client::Node.invoke_request('users::login', lu)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    lu.password = 'foobar'

    olds = Users::Registry.instance.sessions.size

    # valid call
    session = nil
    lambda{
      session = Omega::Client::Node.invoke_request('users::login', lu)
      session.class.should == Users::Session
      session.user_id.should == nu1.id
    }.should_not raise_error

    Users::Registry.instance.sessions.size.should == olds + 1

    # invalid session
    lambda{
      Omega::Client::Node.invoke_request('users::logout', 'session.id')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('users::logout', session.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'user-' + nu1.id)

    olds = Users::Registry.instance.sessions.size

    # valid call
    lambda{
      ret = Omega::Client::Node.invoke_request('users::logout', session.id)
      ret.should be_nil
    }.should_not raise_error

    Users::Registry.instance.sessions.size.should == olds - 1
    Users::Registry.instance.sessions.find { |s| s.id == session.id }.should be_nil
  end

  it "should permit the local node or users with modify users_entities to add_role" do
    nu1 = Users::User.new :id => 'user44', :password => 'foobar'
    nr1 = Users::Role.new :id => 'role43'
    nr2 = Users::Role.new :id => 'role44'
    
    oldu = Users::Registry.instance.users.size

    Users::Registry.instance.create nu1
    Users::Registry.instance.create nr1
    Users::Registry.instance.create nr2

    # exception for local node needs to be overrided
    Omega::Client::Node.node_type = 'local-test'

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('users::add_role', nu1.id, nr1.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'users_entities')

    # invalid user
    lambda{
      Omega::Client::Node.invoke_request('users::add_role', 'non_existant', nr1.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid role
    lambda{
      Omega::Client::Node.invoke_request('users::add_role', nu1.id, 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # valid call
    lambda{
      ret = Omega::Client::Node.invoke_request('users::add_role', nu1.id, nr1.id)
      ret.should be_nil
    }.should_not raise_error

    TestUser.clear_privileges

    Omega::Client::Node.node_type = :local

    # valid call
    lambda{
      Omega::Client::Node.invoke_request('users::add_role', nu1.id, nr2.id)
    }.should_not raise_error

    # duplicate call (no error, but no effect)
    lambda{
      Omega::Client::Node.invoke_request('users::add_role', nu1.id, nr2.id)
    }.should_not raise_error

    nu1.roles.size.should == 2
    nu1.roles.first.should == nr1
    nu1.roles.last.should  == nr2
  end
  
  it "should permit the local node or users with modify users_entities to add_privilege" do
    nr = Users::Role.new :id => 'role43'
    Users::Registry.instance.create nr

    # exception for local node needs to be overrided
    Omega::Client::Node.node_type = 'local-test'

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('users::add_privilege', nr.id, 'view', 'all')
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'users_entities')

    # invalid role
    lambda{
      Omega::Client::Node.invoke_request('users::add_privilege', 'non_existant', 'view', 'all')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # valid call
    lambda{
      ret = Omega::Client::Node.invoke_request('users::add_privilege', nr.id, 'view', 'all')
      ret.should be_nil
    }.should_not raise_error

    TestUser.clear_privileges

    Omega::Client::Node.node_type = :local

    # valid call
    lambda{
      Omega::Client::Node.invoke_request('users::add_privilege', nr.id, 'modify', 'all')
    }.should_not raise_error

    # duplicate call (no error, but no effect)
    lambda{
      Omega::Client::Node.invoke_request('users::add_privilege', nr.id, 'modify', 'all')
    }.should_not raise_error

    nr.privileges.size.should == 2
    nr.privileges.first.id.should == 'view'
    nr.privileges.first.entity_id.should == 'all'
    nr.privileges.last.id.should == 'modify'
    nr.privileges.last.entity_id.should == 'all'
  end

  it "should permit a valid user to register and confirm their registration" do
    nu1 = Users::User.new :id => 'user43', :password => 'foobar', :email => 'invalid'

    old = Users::Registry.instance.users.size

    # not a user instance
    lambda{
      Omega::Client::Node.invoke_request('users::register', "nu1")
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid email
    lambda{
      Omega::Client::Node.invoke_request('users::register', nu1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    nu1.email = 'now@val.id'
    nu1.id = 'omega-test'

    # duplicate user
    lambda{
      Omega::Client::Node.invoke_request('users::register', nu1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    nu1.id = 'user43'
    nu1.password = nil

    # invalid password
    lambda{
      Omega::Client::Node.invoke_request('users::register', nu1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    nu1.password = 'foobar'

    # valid calls
    lambda{
      ru = Omega::Client::Node.invoke_request('users::register', nu1)
      ru.class.should == Users::User
      ru.id.should == nu1.id
      nu1.registration_code.should be_nil # registration code should not be returned
      ru.password.should be_nil # ensure pass returned by server is nil

      du = Users::Registry.instance.users.find { |u| u.id == nu1.id }
      du.should_not be_nil
      du.registration_code.should_not be_nil
      rc = du.registration_code
      du.alliances.empty?.should be_true
      #du.privileges.empty?.should be_true
      du.secure_password.should be_true

      ret = Omega::Client::Node.invoke_request('users::confirm_register', rc)
      ret.should be_nil
    }.should_not raise_error

    Users::Registry.instance.users.size.should == old + 1
  end

  it "should permit a user with modify users_entities to update_user" do
    nu1 = Users::User.new :id => 'user43', :password => 'foobar'
    nu1.secure_password = true

    Users::Registry.instance.create nu1

    uu = Users::User.new :id => 'non_existant', :password => 'foozbar'

    # not a user
    lambda{
      Omega::Client::Node.invoke_request('users::update_user', 'uu')
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    # invalid user id
    lambda{
      Omega::Client::Node.invoke_request('users::update_user', uu)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)
    
    uu.id = 'user43'

    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('users::update_user', uu)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('modify', 'users')

    # valid call
    lambda{
      ru = Omega::Client::Node.invoke_request('users::update_user', uu)
      ru.class.should == Users::User
      ru.id.should == nu1.id
      ru.password.should be_nil # ensure pass returned by server is nil
    }.should_not raise_error

    nu1.secure_password.should == true
    PasswordHelper.check('foozbar', nu1.password).should be_true
  end

  it "should permit local nodes to save and restore state" do
    nu1 = Users::User.new :id => 'user43'
    nu2 = Users::User.new :id => 'user44'

    Users::Registry.instance.create nu1
    Users::Registry.instance.create nu2
    oldu = Users::Registry.instance.users.size

    lambda{
      ret = Omega::Client::Node.invoke_request('users::save_state', '/tmp/users-test')
      ret.should be_nil
    }.should_not raise_error

    Users::Registry.instance.init
    Users::Registry.instance.users.size.should == 0

    lambda{
      ret = Omega::Client::Node.invoke_request('users::restore_state', '/tmp/users-test')
      ret.should be_nil
    }.should_not raise_error

    Users::Registry.instance.users.size.should == oldu
    Users::Registry.instance.users.last.id.should == nu2.id

    FileUtils.rm_f '/tmp/users-test'
  end
end
