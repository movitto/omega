# registry module tests
#
# Copyright (C) 2012-2013-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'users/registry'

module Users
describe Registry do
  context "adding user" do
    it "enforces unique user ids" do
      r = Registry.new
      (r << User.new(:id => 'user1')).should be_true
      r.entities.size.should == 1

      (r << User.new(:id => 'user1')).should be_false
      r.entities.size.should == 1
    end

    it "sets user created at" do
      r = Registry.new
      u = User.new
      r << u
      u.created_at.should_not be_nil
    end

    it "sets user last modified at" do
      r = Registry.new
      u = User.new
      r << u
      u.created_at.should_not be_nil
    end

    it "normalizes user references" do
      r   = Registry.new
      ro  = Role.new :id => 'role1'
      ro1 = Role.new :id => 'role1'
      u   = User.new :roles => [ro]

      r << ro1
      r << u
      u.roles.size.should  ==   1
      u.roles.first.should == ro1
    end
  end

  context "adding role" do
    it "enforces unique role ids" do
      r = Registry.new
      (r << Role.new(:id => 'role1')).should be_true
      r.entities.size.should == 1

      (r << Role.new(:id => 'role1')).should be_false
      r.entities.size.should == 1
    end
  end

  context "adding session" do
    it "enforces unique session user_ids" do
      r = Registry.new
      u = User.new(:id => 'user1')
      r << u

      (r << Session.new(:user => u)).should be_true
      r.entities.size.should == 2

      (r << Session.new(:user => u)).should be_false
      r.entities.size.should == 2
    end

    it "normalizes session references" do
      r  = Registry.new
      u  = User.new :id => 'user1'
      u1 = User.new :id => 'user1'
      s  = Session.new :user => u

      r << u1
      r << s
      s.user.should == u1
    end
  end

  describe "#valid_login?" do
    before(:each) do
      @r = Registry.new
      @u = User.new :id => 'user1', :password => 'foobar',
                    :secure_password => true,
                    :registration_code => nil
      @r << @u
    end

    context "user cannot be found" do
      it "returns false" do
        @r.valid_login?('user2', 'anything').should be_false
      end
    end

    context "invalid credentalis" do
      it "returns false" do
        @r.valid_login?('user1', 'barfoo').should be_false
      end
    end

    context "valid credentials" do
      it "returns true" do
        @r.valid_login?('user1', 'foobar').should be_true
      end
    end
  end

  describe "#create_session" do
    context "no existing user session" do
      before(:each) do
        @u = User.new :id => 'user1'
        @r = Registry.new
        @r << @u
      end

      it "adds new session to registry" do
        @r.entities.size.should == 1

        @r.create_session(@u)
        @r.entities.size.should == 2
        @r.entities.first.id.should == @u.id
        @r.entities.last.should be_an_instance_of(Session)
        @r.entities.last.user.id.should == @u.id
      end

      it "returns new session" do
        s = @r.create_session(@u)
        s.should be_an_instance_of(Session)
        s.user.should == @u
      end

      it "sets user last login time" do
        s = @r.create_session(@u)
        s.user.last_login_at.should_not be_nil
      end
    end

    context "existing user session" do
      before(:each) do
        @u = User.new
        @r = Registry.new
        @r << @u
        @s = @r.create_session(@u)
      end

      context "session timed out" do
        before(:each) do
          @s.expire!
        end

        it "destroys current session" do
          @r.create_session(@u)
          @r.entities.size.should == 2
          @r.entities.collect { |e| e.id }.should_not include(@s.id)
        end

        it "returns new session" do
          s1 = @r.create_session(@u)
          s1.should_not == @s
        end
      end

      context "session still valid" do
        it "returns current session" do
          s1 = @r.create_session(@u)
          s1.id.should == @s.id
        end
      end
    end
  end

  describe "#destroy_session" do
    before(:each) do
      @u = User.new :id => 'user1'
      @r = Registry.new
      @r << @u
      @s = @r.create_session(@u)
    end

    it "destroys session by id" do
      @r.destroy_session :session_id => @s.id
      @r.entities.collect { |e| e.id }.should_not include(@s.id)
    end

    it "destroys session by user id" do
      @r.destroy_session :user_id => @u.id
      @r.entities.collect { |e| e.id }.should_not include(@s.id)
    end
  end

  describe "#require_privilege" do
    it "uses check privilege" do
      r = Registry.new
      r.should_receive(:check_privilege).with(:args).and_return(true)
      r.require_privilege :args
    end

    context "check_privilege returns false" do
      it "raises PermissionError" do
        r = Registry.new
        r.should_receive(:check_privilege).and_return(false)
        lambda {
          r.require_privilege :args
        }.should raise_error(Omega::PermissionError)
      end
    end

    context "check_privilege returns true" do
      it "does not raise error" do
        r = Registry.new
        r.should_receive(:check_privilege).and_return(true)
        lambda {
          r.require_privilege :args
        }.should_not raise_error
      end
    end
  end

  describe "#check_privilege" do
    before(:each) do
      @r  = Registry.new
      @p1 = Privilege.new :id => 'modify', :entity_id => 'users'
      @p2 = Privilege.new :id => 'view'
      @ro = Role.new :privileges => [@p1, @p2]
      @u  = User.new :id => 'user1', :roles => [@ro]
      @r  << @ro
      @r  << @u
      @s  = @r.create_session(@u)
    end

    context "user perms disabled" do
      before(:all) do
        @upe = Registry.user_perms_enabled
      end

      after(:all) do
        Registry.user_perms_enabled = @upe
      end

      it "returns true" do
        Registry.user_perms_enabled = false
        @r.check_privilege("anything").should be_true
      end
    end

    context "specified session not found" do
      it "returns false" do
        @r.check_privilege(:session => 'non_existant').should be_false
      end
    end

    context "specified session timed out" do
      before(:each) do
        @s.expire!
      end

      it "destroys session" do
        @r.check_privilege(:session => @s.id)
        @r.entities.size.should == 2
        @r.entities.collect { |e| e.id }.should_not include(@s.id)
      end

      it "returns false" do
        @r.check_privilege(:session => @s.id).should be_false
      end
    end

    context "single privilege specified" do
      context "entity specified" do
        context "session user has privilege on entity" do
          it "returns true" do
            @r.check_privilege(:session   => @s.id,
                               :privilege => 'modify',
                               :entity    => 'users').should be_true
          end
        end

        context "session user does not have privilege on entity" do
          it "returns false" do
            @r.check_privilege(:session   => @s.id,
                               :privilege => 'modify',
                               :entity    => 'locations').should be_false
            @r.check_privilege(:session   => @s.id,
                               :privilege => 'view',
                               :entity    => 'users').should be_false
          end
        end
      end

      context "entity not specified" do
        context "session user has privilege" do
          it "returns true" do
            @r.check_privilege(:session   => @s.id,
                               :privilege => 'view').should be_true
          end
        end

        context "session user does not have privilege" do
          it "returns false" do
            @r.check_privilege(:session   => @s.id,
                               :privilege => 'modify').should be_false
          end
        end
      end
    end

    context "list of :any privileges specified" do
      context "entity specified" do
        context "session user has at least one privilege on entity" do
          it "returns true" do
            @r.check_privilege(:session   => @s.id,
                               :any       =>
                                 [{ :privilege => 'modify',
                                    :entity    => 'users'},
                                  { :privilege => 'modify',
                                    :entity    => 'locations'}]).should be_true
          end
        end

        context "session user does not have any of privileges" do
          it "returns false" do
            @r.check_privilege(:session   => @s.id,
                               :any       =>
                                 [{ :privilege => 'view',
                                    :entity    => 'users'},
                                  { :privilege => 'view',
                                    :entity    => 'locations'}]).should be_false
          end
        end
      end

      context "entity not specified" do
        context "session user has at least one privilege" do
          it "returns true" do
            @r.check_privilege(:session   => @s.id,
                               :any       =>
                                 [{ :privilege => 'modify'},
                                  { :privilege => 'view'}]).should be_true
          end
        end

        context "session user does not have any of privileges" do
          it "returns false" do
            @r.check_privilege(:session   => @s.id,
                               :any       =>
                                 [{ :privilege => 'modify'},
                                  { :privilege => 'create'}]).should be_false
          end
        end
      end
    end
  end

  describe "#current_user" do
    before(:each) do
      @u = User.new
      @r = Registry.new
      @r << @u
      @s = @r.create_session(@u)
    end

    context "specified session not found" do
      it "returns nil" do
        r = Registry.new
        u = r.current_user :session => 'nonexisting'
        u.should be_nil
      end
    end

    context "specified session timed out" do
      before(:each) do
        @s.expire!
      end

      it "deletes session" do
        @r.current_user :session => @s.id
        @r.entities.size.should == 1
        @r.entities.collect { |e| e.id }.should_not include(@s.id)
      end

      it "returns nil" do
        @u = @r.current_user :session => @s.id
        @u.should be_nil
      end
    end

    context "specified session is valid" do
      it "returns session user" do
        @u = @r.current_user :session => @s.id
        @u.id.should == @u.id
      end
    end
  end

end # describe Registry
end # module Users
