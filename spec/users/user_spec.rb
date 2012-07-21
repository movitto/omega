# user module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Users::User do

  it "should properly initialze user" do
    u = Users::User.new :id => 'user1', :email => 'u@ser.com', :password => 'foobar'
    u.id.should       == 'user1'
    u.email.should    == 'u@ser.com'
    u.password.should == "foobar"
    u.alliances.size.should == 0
    u.privileges.size.should == 0
  end

  it "should properly secure user password" do
    u = Users::User.new :id => 'user1', :email => 'u@ser.com', :password => 'foobar'
    u.secure_password = true

    # password should be salted
    u.password.should_not == "foobar"
    PasswordHelper.check('foobar', u.password)
  end

  it "should permit password to be update" do
    u = Users::User.new :password => 'foobar'
    u.password.should == 'foobar'

    ct = Time.now
    n = Users::User.new :password => 'barfoo'
    u.secure_password = true
    u.update!(n)
    PasswordHelper.check('barfoo', u.password).should be_true

    u.last_modified_at.should_not be_nil
    u.last_modified_at.class.should == Time
    u.last_modified_at.should > ct
    u.last_modified_at.should < Time.now
  end

  it "should permit adding an alliance" do
    a = Users::Alliance.new :id => 'a1'
    b = Users::Alliance.new :id => 'a2'
    u = Users::User.new
    u.alliances.size.should == 0
    u.add_alliance(a)
    u.alliances.size.should == 1
    u.alliances.first.should == a
    u.add_alliance(a)
    u.alliances.size.should == 1
    u.add_alliance(u)
    u.alliances.size.should == 1
    u.add_alliance(b)
    u.alliances.size.should == 2
  end

  it "should permit adding and removing privileges" do
    p = Users::Privilege.new
    u = Users::User.new
    u.privileges.size.should == 0
    u.add_privilege(p)
    u.privileges.size.should == 1
    u.privileges.first.should == p
    u.add_privilege(p)
    u.privileges.size.should == 1
  end

  it "should not permit adding duplicate privileges" do
    p1 = Users::Privilege.new :id => 'p', :entity_id => 1
    p2 = Users::Privilege.new :id => 'p', :entity_id => 1
    u = Users::User.new
    u.add_privilege(p1)
    u.add_privilege(p2)
    u.privileges.size.should == 1
  end

  it "should validate emails" do
    u = Users::User.new
    u.valid_email?.should be_false

    u.email = 'foobar'
    u.valid_email?.should be_false

    u.email = 'foo@bar'
    u.valid_email?.should be_false

    u.email = 'foo@bar.com'
    u.valid_email?.should be_true
  end

  it "should validate login" do
    u = Users::User.new :id => 'user1', :password => 'foobar'
    u.valid_login?('user1', 'foobar').should be_true

    u.valid_login?('user1', 'barfoo').should be_false
    u.valid_login?('user2', 'foobar').should be_false

    u.registration_code = '1111'
    u.valid_login?('user2', 'foobar').should be_false
  end

  it "should validate login when password is secure" do
    u = Users::User.new :id => 'user1', :password => 'foobar'
    u.secure_password = true
    u.valid_login?('user1', 'foobar').should be_true
    u.valid_login?('user1', 'barfoo').should be_false
  end

  it "should validate privileges" do
    u = Users::User.new :id => 'user1', :password => 'foobar'
    p1 = Users::Privilege.new :id => 'view', :entity_id => 'entity1'
    p2 = Users::Privilege.new :id => 'modify'
    u.add_privilege(p1)
    u.add_privilege(p2)

    u.has_privilege_on?('view', 'entity1').should be_true
    u.has_privilege?('modify').should be_true

    u.has_privilege?('view').should be_false
    u.has_privilege_on?('view', 'entity2').should be_false
    u.has_privilege_on?('modify', 'entity1').should be_false
  end

  it "should be convertable to json" do
    user = Users::User.new :id => 'user42',
                           :email => 'user@42.omega', :password => 'foobar',
                           :alliances => [Users::Alliance.new(:id => 'alliance1')]

    j = user.to_json
    j.should include('"json_class":"Users::User"')
    j.should include('"id":"user42"')
    j.should include('"email":"user@42.omega"')
    j.should include('"password":"foobar"')
    j.should include('"json_class":"Users::Alliance"')
    j.should include('"id":"alliance1"')
  end

  it "should not include password in json if secure" do
    user = Users::User.new :id => 'user42',
                           :email => 'user@42.omega', :password => 'foobar',
                           :alliances => [Users::Alliance.new(:id => 'alliance1')]
    user.secure_password = true

    j = user.to_json
    j.should_not include('password')
  end

  it "should be convertable from json" do
    j = '{"data":{"email":"user@42.omega","password":"foobar","alliances":[{"data":{"enemy_ids":[],"member_ids":[],"id":"alliance1"},"json_class":"Users::Alliance"}],"id":"user42"},"json_class":"Users::User"}'
    u = JSON.parse(j)

    u.class.should == Users::User
    u.id.should == "user42"
    u.email.should == 'user@42.omega'
    u.password.should == 'foobar'
    u.alliances.size.should == 1
    u.alliances.first.id.should == 'alliance1'
  end

end
