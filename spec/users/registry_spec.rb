# registry module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

require 'stringio'

describe Users::Registry do

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

    Users::Registry.instance.create u1
    Users::Registry.instance.users.size.should == 1

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
  end

  it "should manage sessions" do
    Users::Registry.instance.init
    u = Users::User.new :id => 'user42'
    Users::Registry.instance.create u

    session = Users::Registry.instance.create_session u
    session.user.should == u
    Users::Registry.instance.sessions.should include(session)

    found = Users::Registry.instance.find :session_id => session.id
    found.size.should == 1
    found.first.should == u

    Users::Registry.instance.destroy_session session.id
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

    u.add_privilege Users::Privilege.new(:id => 'view', :entity_id => 'locations')

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

    u.add_privilege Users::Privilege.new(:id => 'modify')

    lambda{
      Users::Registry.require_privilege :session => session.id,
                                        :any     => [{:privilege => 'modify', :entity    => 'locations'},
                                                     {:privilege => 'modify'}]
    }.should_not raise_error
  end

  it "should save registered users entities to io object" do
    Users::Registry.instance.init
    u = Users::User.new :id => 'user42'
    Users::Registry.instance.create u
    u.add_privilege Users::Privilege.new(:id => 'view', :entity_id => 'locations')

    sio = StringIO.new
    Users::Registry.instance.save_state(sio)
    s = sio.string
    s.should include('"json_class":"Users::User"')
    s.should include('"id":"user42"')
    s.should include('"json_class":"Users::Privilege"')
    s.should include('"id":"view"')
    s.should include('"entity_id":"locations"')
  end

  it "should restore users entities from io object" do
    s = '{"data":{"email":null,"password":null,"id":"user42","alliances":[]},"json_class":"Users::User"}' + "\n" +
        '{"data":{"entity_id":"locations","id":"view"},"json_class":"Users::Privilege"}'
    a = s.collect { |i| i }

    Users::Registry.instance.init
    Users::Registry.instance.restore_state(a)
    Users::Registry.instance.users.size.should == 1

    u = Users::Registry.instance.find :id => 'user42'
    u.size.should == 1
    u.first.id.should == 'user42'
    u.first.has_privilege_on?('view', 'locations').should be_true
  end

end
