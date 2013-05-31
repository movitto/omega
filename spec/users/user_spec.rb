# user module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'users/user'

module Users
describe User do

  describe "#initialize" do
    it "sets attributes" do
      u = User.new :id => 'user1', :email => 'u@ser.com', :password => 'foobar'
      u.id.should        == 'user1'
      u.email.should     == 'u@ser.com'
      u.password.should  == "foobar"
      u.permenant.should == false
      u.npc.should       == false
      u.roles.should     == nil
      u.privileges.size.should == 0

      u = User.new :npc => true
      u.npc.should       == true
    end

    it "sets user on attributes" do
      a = Attribute.new :type => OmegaTest::Attribute
      u = User.new :attributes => [a]
      a.user.should == u
    end
  end

  describe "secure_password" do
    context "set to true" do
      it "encrypts password" do
        u = User.new :id => 'user1', :email => 'u@ser.com', :password => 'foobar'
        u.secure_password = true

        # password should be salted
        u.password.should_not == "foobar"
        PasswordHelper.check('foobar', u.password)
      end
    end
  end

  describe "#update" do
    it "updates password" do
      u = User.new :password => 'foobar'
      n = User.new :password => 'barfoo'
      u.secure_password = true

      PasswordHelper.check('foobar', u.password).should be_true
      u.update(n)
      PasswordHelper.check('barfoo', u.password).should be_true
    end

    it "updates registration code" do
      u = User.new :registration_code => 'foobar'
      n = User.new :registration_code => nil

      u.registration_code.should == 'foobar'
      u.update(n)
      u.registration_code.should be_nil
    end

    context "roles are set" do
      it "updates roles" do
        u = User.new :roles => [Role.new(:id => 'role1')]
        n = User.new :roles => [Role.new(:id => 'role2')]

        u.roles.first.id.should == 'role1'
        u.update(n)
        u.roles.first.id.should == 'role2'
      end
    end

    context "roles are not set" do
      it "does not update roles" do
        u = User.new :roles => [Role.new(:id => 'role1')]
        n = User.new

        u.roles.first.id.should == 'role1'
        u.update(n)
        u.roles.first.id.should == 'role1'
      end
    end

    context "attributes are set" do
      it "updates attributes" do
        a1 = Attribute.new
        a2 = Attribute.new
        u = User.new :attributes => [a1]
        n = User.new :attributes => [a2]

        u.attributes.first.should == a1
        u.update(n)
        u.attributes.first.should == a2
      end
    end

    context "attributes are not set" do
      it "does not update attributes" do
        a = Attribute.new
        u = User.new :attributes => [a]
        n = User.new

        u.attributes.first.should == a
        u.update(n)
        u.attributes.first.should == a
      end
    end

    it "sets last modified time" do
      u = User.new :password => 'foobar'
      ct = Time.now
      u.update(User.new)
      u.last_modified_at.should_not be_nil
      u.last_modified_at.class.should == Time
      u.last_modified_at.should > ct
      u.last_modified_at.should < Time.now
    end
  end

  describe "#update_attribute" do
    it "updates attribute" do
      a = Attribute.new :type => OmegaTest::Attribute
      u = User.new :attributes => [a]
      u.update_attribute!(OmegaTest::Attribute.id, 5)
      a.level.should == 5
      a.user.should == u
    end

    it "creates missing attributes" do
      u = User.new
      u.update_attribute!(OmegaTest::Attribute.id, 5)
      a = u.attributes.find { |a| a.type == OmegaTest::Attribute }
      a.level.should == 5
      a.user.should == u
    end
  end

  describe "#has_attribute?" do
    context "level not specified" do
      context "user has attribute" do
        it "returns true" do
          a = Attribute.new :type => OmegaTest::Attribute
          u = User.new :attributes => [a]
          u.has_attribute?(OmegaTest::Attribute.id).should be_true
        end
      end

      context "user does not have attribute" do
        it "returns false" do
          a = Attribute.new :type => OmegaTest::Attribute
          u = User.new :attributes => [a]
          u.has_attribute?(:fooz).should be_false
        end
      end
    end

    context "level specified" do
      context "user has attribute >= level" do
        it "returns true" do
          a = Attribute.new :type => OmegaTest::Attribute, :level => 5
          u = User.new :attributes => [a]
          u.has_attribute?(OmegaTest::Attribute.id, 4).should be_true
          u.has_attribute?(OmegaTest::Attribute.id, 5).should be_true
        end
      end

      context "user does not have attribute >= level" do
        it "returns false" do
          a = Attribute.new :type => OmegaTest::Attribute, :level => 5
          u = User.new :attributes => [a]
          u.has_attribute?(OmegaTest::Attribute.id, 6).should be_false
        end
      end
    end
  end

  describe "#clear_roles" do
    it "empties role list"
  end

  describe "#add_role" do
    it "adds role" do
      r = Role.new
      u = User.new
      u.roles.should be_nil
      u.add_role(r)
      u.roles.size.should == 1
      u.roles.first.should == r
      u.add_role(r)
      u.roles.size.should == 1
    end

    it "only adds role once" do
      r1 = Role.new :id => 'r'
      r2 = Role.new :id => 'r'
      u = User.new
      u.add_role(r1)
      u.add_role(r2)
      u.roles.size.should == 1
    end
  end

  describe "#valid?" do
    before(:each) do
      @u = User.new :id => 'foobar', :password => 'barfoo',
                    :email => 'foo@b.ar'
    end

    context "valid user" do
      it "returns true" do
        @u.should be_valid
      end
    end

    context "invalid email" do
      it "returns false" do
        @u.email = 'in@valid'
        @u.should_not be_valid
      end
    end

    context "indvalid id" do
      it "returns false" do
        @u.id = 123
        @u.should_not be_valid
        @u.id = ""
        @u.should_not be_valid
        @u.id = nil
        @u.should_not be_valid
      end
    end

    context "invalid password" do
      it "returns false" do
        @u.password = 123
        @u.should_not be_valid
        @u.password = ""
        @u.should_not be_valid
        @u.password = nil
        @u.should_not be_valid
      end
    end
  end

  describe "#valid_email?" do
    context "email is valid" do
      it "returns true" do
        u = User.new
        u.email = 'foo@bar.com'
        u.valid_email?.should be_true
      end
    end

    context "email is not valid" do
      it "returns false" do
        u = User.new
        u.valid_email?.should be_false

        u.email = 'foobar'
        u.valid_email?.should be_false

        u.email = 'foo@bar'
        u.valid_email?.should be_false
      end
    end
  end

  describe "#valid_login?" do
    context "credentials are valid" do
      it "returns true" do
        u = User.new :id => 'user1', :password => 'foobar'
        u.valid_login?('user1', 'foobar').should be_true

        u.secure_password = true
        u.valid_login?('user1', 'foobar').should be_true
      end
    end

    context "credentials are not valid" do
      it "return false" do
        u = User.new :id => 'user1', :password => 'foobar'
        u.valid_login?('user1', 'barfoo').should be_false
        u.valid_login?('user2', 'foobar').should be_false

        u.secure_password = true
        u.valid_login?('user1', 'barfoo').should be_false
      end
    end

    context "registration code is set" do
      it "always returns false" do
        u = User.new :id => 'user1', :password => 'foobar'
        u.registration_code = '1111'
        u.valid_login?('user1', 'foobar').should be_false
      end
    end
  end

  describe "#privileges" do
    it "returns privileges in all assigned roles" do
      r1 = Role.new :privileges => [:p1]
      r2 = Role.new :privileges => [:p2]
      u = User.new :roles => [r1, r2]
      u.privileges.should == [:p1, :p2]
    end

    it "removes duplicate privileges" do
      r1 = Role.new :privileges => [:p1, :p2]
      r2 = Role.new :privileges => [:p2, :p3]
      u = User.new :roles => [r1, r2]
      u.privileges.should == [:p1, :p2, :p3]
    end
  end

  describe "#has_privilege_on?" do
    context "user has role with privilege on entity" do
      it "returns true" do
        u = User.new :id => 'user1', :password => 'foobar'
        p = Privilege.new :id => 'view', :entity_id => 'entity1'
        r = Role.new :privileges => [p]
        u.add_role(r)

        u.has_privilege_on?('view', 'entity1').should be_true
      end
    end

    context "user does not have role with privilege on entity" do
      it "returns false" do
        u = User.new :id => 'user1', :password => 'foobar'
        p = Privilege.new :id => 'view', :entity_id => 'entity1'
        r = Role.new :privileges => [p]
        u.add_role(r)
        u.has_privilege_on?('view', 'entity2').should be_false
        u.has_privilege_on?('modify', 'entity1').should be_false
      end
    end
  end

  describe "#has_privilege" do
    context "user has role with privilege" do
      it "returns true" do
        u = User.new :id => 'user1', :password => 'foobar'
        p = Privilege.new :id => 'modify'
        r = Role.new :privileges => [p]
        u.add_role(r)
        u.has_privilege?('modify').should be_true
      end
    end

    context "user does not have role with privilege on entity" do
      it "returns false" do
        u = User.new :id => 'user1', :password => 'foobar'
        p = Privilege.new :id => 'modify'
        r = Role.new :privileges => [p]
        u.add_role(r)
        u.has_privilege_on?('view', 'entity2').should be_false
        u.has_privilege_on?('modify', 'entity1').should be_false
        u.has_privilege?('view').should be_false
      end
    end
  end

  describe "#to_json" do
    it "returns user in json format" do
      user = User.new :id => 'user42',
                             :email => 'user@42.omega', :password => 'foobar'

      j = user.to_json
      j.should include('"json_class":"Users::User"')
      j.should include('"id":"user42"')
      j.should include('"email":"user@42.omega"')
      j.should include('"password":"foobar"')
      j.should include('"permenant":false')
      j.should include('"npc":false')
    end

    context "secure_password set true" do
      it "does not encode password" do
        user = User.new :id => 'user42',
                        :email => 'user@42.omega', :password => 'foobar'
        user.secure_password = true
        j = user.to_json
        j.should_not include('password')
      end

      it "does not encode registration code" do
        user = User.new :id => 'user42',
                        :email => 'user@42.omega', :password => 'foobar'
        user.secure_password = true
        j = user.to_json
        j.should_not include('registration_code')
      end
    end
  end

  describe "#json_create" do
    it "returns user from json format" do
      j = '{"data":{"email":"user@42.omega","password":"foobar","id":"user42"},"json_class":"Users::User"}'
      u = JSON.parse(j)

      u.class.should == Users::User
      u.id.should == "user42"
      u.email.should == 'user@42.omega'
      u.password.should == 'foobar'
    end
  end

  describe "#random_registration_code" do
    it "generates random 8 char string"
  end

end # describe User
end # module Users
