# registry module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'stringio'
require 'timecop'

describe Users::Registry do

  after(:all) do
    Timecop.return
  end

  it "provide access to managed users entities" do
    Users::Registry.instance.init
    Users::Registry.instance.users.size.should == 0
    Users::Registry.instance.alliances.size.should == 0
    Users::Registry.instance.sessions.size.should == 0

    u1 = Users::User.new :id => 'user1'
    u2 = Users::User.new :id => 'user1'
    u3 = Users::User.new :id => 'user3'
    u3.registration_code = 'foobar'
    a1  = Users::Alliance.new :id => 'alliance1'
    a2  = Users::Alliance.new :id => 'alliance1'

    ct = Time.now

    Users::Registry.instance.create u1
    Users::Registry.instance.users.size.should == 1

    # ensure created_at timestamp gets set
    u1.created_at.should_not be_nil
    u1.created_at.class.should == Time
    u1.created_at.should > ct
    u1.created_at.should < Time.now

    Users::Registry.instance.create u2
    Users::Registry.instance.users.size.should == 1

    Users::Registry.instance.create u3
    Users::Registry.instance.users.size.should == 2

    Users::Registry.instance.create a1
    Users::Registry.instance.alliances.size.should == 1

    Users::Registry.instance.create a2
    Users::Registry.instance.alliances.size.should == 1

    found = Users::Registry.instance.find :id => 'user1'
    found.size.should == 1
    found.first.should == u1

    found = Users::Registry.instance.find :registration_code => 'foobar'
    found.size.should == 1
    found.first.should == u3

    found = Users::Registry.instance.find :type => "Users::User"
    found.size.should == 2
    found[0].should == u1
    found[1].should == u3

    found = Users::Registry.instance.find :type => "Users::User",
                                          :id   => "user5"
    found.size.should == 0

    # ensure entity removal and removing user destroys session
    session = Users::Registry.instance.create_session u2
    Users::Registry.instance.remove u2.id
    Users::Registry.instance.users.size.should == 1
    found = Users::Registry.instance.find :id => u2.id
    found.size.should == 0
    Users::Registry.instance.sessions.should_not include(session)
  end

  it "should return users which have the specified privilege" do
    u1 = Users::User.new :id => 'user42'
    u2 = Users::User.new :id => 'user43'
    u3 = Users::User.new :id => 'user44'
    Users::Registry.instance.create u1
    Users::Registry.instance.create u2
    Users::Registry.instance.create u3

    role1 = Users::Role.new(:id => 'role1', :privileges => [Users::Privilege.new(:id => 'view', :entity_id => 'manufactured_entities')])
    u1.add_role role1 
    u2.add_role role1

    users = Users::Registry.instance.find :with_privilege => ['view', 'manufactured_entities']
    users.size.should == 2
    users.should include(u1)
    users.should include(u2)
    users.should_not include(u3)
  end

  it "should manage sessions" do
    Users::Registry.instance.init
    u = Users::User.new :id => 'user42'
    Users::Registry.instance.create u

    ct = Time.now

    session = Users::Registry.instance.create_session u
    session.user.should == u
    Users::Registry.instance.sessions.should include(session)

    # ensure last_login_at timestamp gets created
    u.last_login_at.should_not be_nil
    u.last_login_at.class.should == Time
    u.last_login_at.should > ct
    u.last_login_at.should < Time.now

    found = Users::Registry.instance.find :session_id => session.id
    found.size.should == 1
    found.first.should == u

    Users::Registry.instance.destroy_session :session_id => session.id
    Users::Registry.instance.sessions.should_not include(session)
  end

  it "should provide means to enforce user privileges" do
    Users::Registry.instance.init
    u = Users::User.new :id => 'user42'
    Users::Registry.instance.create u

    lambda{
      Users::Registry.require_privilege :session => "aaaa",
                                        :privilege => 'view',
                                        :entity    => 'locations'
    }.should raise_error(Omega::PermissionError, "session not found")

    session = Users::Registry.instance.create_session u

    lambda{
      Users::Registry.require_privilege :session => session.id,
                                        :privilege => 'view',
                                        :entity    => 'locations'
    }.should raise_error(Omega::PermissionError, "user user42 does not have required privilege view on locations")

    role1 = Users::Role.new(:id => 'role1', :privileges => [Users::Privilege.new(:id => 'view', :entity_id => 'locations')])
    u.add_role role1

    lambda{
      Users::Registry.require_privilege :session => session.id,
                                        :privilege => 'view',
                                        :entity    => 'locations'
    }.should_not raise_error

    lambda{
      Users::Registry.require_privilege :session => session.id,
                                        :any     => [{:privilege => 'modify', :entity    => 'locations'},
                                                     {:privilege => 'modify'}]
    }.should raise_error(Omega::PermissionError)

    role1.add_privilege Users::Privilege.new(:id => 'modify')

    lambda{
      Users::Registry.require_privilege :session => session.id,
                                        :any     => [{:privilege => 'modify', :entity    => 'locations'},
                                                     {:privilege => 'modify'}]
    }.should_not raise_error
  end

  it "should provide means to query user privileges" do
    Users::Registry.instance.init
    u = Users::User.new :id => 'user42'
    Users::Registry.instance.create u

    Users::Registry.check_privilege(:session => 'aaa',
                                    :privilege => 'view',
                                    :entity => 'locations').should be_false # no session

    session = Users::Registry.instance.create_session u

    Users::Registry.check_privilege(:session => session.id,
                                    :privilege => 'view',
                                    :entity => 'locations').should be_false # no privilege

    role1 = Users::Role.new(:id => 'role1', :privileges => [Users::Privilege.new(:id => 'view', :entity_id => 'locations')])
    u.add_role role1

    Users::Registry.check_privilege(:session => session.id,
                                    :privilege => 'view',
                                    :entity => 'locations').should be_true

    Users::Registry.check_privilege(:session => session.id,
                                    :any     => [{:privilege => 'modify', :entity    => 'locations'},
                                                 {:privilege => 'modify'}]).should be_false # no privilege

    role1.add_privilege Users::Privilege.new(:id => 'modify')

    Users::Registry.check_privilege(:session => session.id,
                                    :any     => [{:privilege => 'modify', :entity    => 'locations'},
                                                 {:privilege => 'modify'}]).should be_true
  end

  it "should provide access to current user" do
    Users::Registry.instance.init
    u = Users::User.new :id => 'user42'
    Users::Registry.instance.create u

    cu = Users::Registry.current_user :session => 'aaa'
    cu.should be_nil

    session = Users::Registry.instance.create_session u
    cu = Users::Registry.current_user :session => session.id
    cu.should == u
  end

  it "should check session validity before checking privilege" do
    Users::Registry.instance.init
    u = Users::User.new :id => 'user42'
    Users::Registry.instance.create u
    session = Users::Registry.instance.create_session u
    role1 = Users::Role.new(:id => 'role1', :privileges => [Users::Privilege.new(:id => 'view', :entity_id => 'locations')])
    u.add_role role1

    lambda{
      Users::Registry.require_privilege :session => session.id,
                                        :privilege => 'view',
                                        :entity    => 'locations'
    }.should_not raise_error

    Timecop.travel(Users::Session::SESSION_EXPIRATION + 1)

    lambda{
      Users::Registry.require_privilege :session => session.id,
                                        :privilege => 'view',
                                        :entity    => 'locations'
    }.should raise_error(Omega::PermissionError)

    Users::Registry.instance.sessions.find { |s| s.id == session.id }.should be_nil
  end

  it "should check session validity before returning current user" do
    Users::Registry.instance.init
    u = Users::User.new :id => 'user42'
    Users::Registry.instance.create u
    session = Users::Registry.instance.create_session u
    cu = Users::Registry.current_user :session => session.id
    cu.should == u

    Timecop.travel(Users::Session::SESSION_EXPIRATION + 1)
    cu = Users::Registry.current_user :session => session.id
    cu.should be_nil
    Users::Registry.instance.sessions.find { |s| s.id == session.id }.should be_nil
  end

  it "should save registered users entities to io object" do
    Users::Registry.instance.init
    u = Users::User.new :id => 'user42'
    Users::Registry.instance.create u
    role1 = Users::Role.new(:id => 'role1', :privileges => [Users::Privilege.new(:id => 'view', :entity_id => 'locations')])
    u.add_role role1
    a = Users::Alliance.new :id => 'aly123'
    Users::Registry.instance.create a

    sio = StringIO.new
    Users::Registry.instance.save_state(sio)
    s = sio.string
    s.should include('"json_class":"Users::User"')
    s.should include('"id":"user42"')
    s.should include('"json_class":"Users::Privilege"')
    s.should include('"id":"view"')
    s.should include('"entity_id":"locations"')
    s.should include('"json_class":"Users::Alliance"')
    s.should include('"id":"aly123"')
  end

  it "should restore users entities from io object" do
    s = '{"data":{"email":null,"password":null,"id":"user42","alliances":[]},"json_class":"Users::User"}' + "\n" +
        '{"data":{"entity_id":"locations","id":"view"},"json_class":"Users::Privilege"}' + "\n" +
        '{"json_class":"Users::Alliance","data":{"member_ids":["user42"],"enemy_ids":[],"id":"alliance42"}}'
    a = s.split "\n"

    Users::Registry.instance.init
    Users::Registry.instance.restore_state(a)
    Users::Registry.instance.users.size.should == 1
    Users::Registry.instance.alliances.size.should == 1

    u = Users::Registry.instance.find :id => 'user42'
    u.size.should == 1
    u.first.id.should == 'user42'
    u.first.has_privilege_on?('view', 'locations').should be_true

    a = Users::Registry.instance.find :id => 'alliance42'
    a.size.should == 1
    a.first.id.should == 'alliance42'
    a.first.members.size.should == 1
    a.first.members.first.should == u.first
  end

end
