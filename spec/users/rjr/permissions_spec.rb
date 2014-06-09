# users::add_role, users::add_privilege tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/get'
require 'rjr/dispatcher'

module Users::RJR
  describe "#add_role", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :PERMISSION_METHODS
      @registry = Users::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "not local node" do
      before(:each) do
        # change the node type
        @n.node_type = 'local-test'
      end

      context "insufficient privileges (modify-roles)" do
        it "raises PermissionError" do
          user = create(:user)
          role = create(:role)
          lambda {
            @s.add_role(user.id, role.id)
          }.should raise_error(PermissionError)
        end
      end

      context "sufficient privileges (modify-roles)" do
        it "does not raise PermissionError" do
          add_privilege(@login_role, 'modify', 'roles')
          user = create(:user)
          role = create(:role)
          lambda {
            @s.add_role(user.id, role.id)
          }.should_not raise_error
        end
      end
    end

    context "user not found" do
      it "raises DataNotFound" do
        role = create(:role)
        lambda {
          @s.add_role('non-existant', role.id)
        }.should raise_error(DataNotFound)
      end
    end

    context "role not found" do
      it "raises DataNotFound" do
        user = create(:user)
        lambda {
          @s.add_role(user.id, 'nonexistant')
        }.should raise_error(DataNotFound)
      end
    end

    it "adds role to user" do
      user = create(:user)
      role = create(:role)
      @s.add_role(user.id, role.id)
      @registry.entity(&with_id(user.id)).
                roles.collect { |r| r.id }.should include(role.id)
    end

    it "returns nil" do
      user = create(:user)
      role = create(:role)
      @s.add_role(user.id, role.id).should be_nil
    end

  end # describe #add_role

  describe "#remove_role", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :PERMISSION_METHODS
      @registry = Users::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)

      @role1 = create(:role)
      @role  = create(:role)
      @role.add_privilege('view')
      @role.add_privilege('modify', 'ship')
      @user = create(:user, :roles => [@role])
      @ruser = @registry.proxy_for(&with_id(@user.id))
    end

    context "local node" do
      it "does not raise permission error" do
        lambda {
          @s.remove_role(@user.id, @role.id)
        }.should_not raise_error
      end
    end

    context "not local node" do
      before(:each) do
        # change the node type
        @n.node_type = 'local-test'
      end

      context "insufficient privileges (modify-roles)" do
        it "raises PermissionError" do
          lambda {
            @s.remove_role(@user.id, @role.id)
          }.should raise_error(PermissionError)
        end
      end

      context "sufficient privileges (modify-roles)" do
        it "does not raise PermissionError" do
          add_privilege(@login_role, 'modify', 'roles')
          lambda {
            @s.remove_role(@user.id, @role.id)
          }.should_not raise_error
        end
      end
    end

    context "user not found" do
      it "raises DataNotFound" do
        lambda {
          @s.remove_role('invalid', @role.id)
        }.should raise_error(DataNotFound)
      end
    end

    context "role not found" do
      it "raises DataNotFound" do
        lambda {
          @s.remove_role(@user.id, 'foobar')
        }.should raise_error(DataNotFound)
      end
    end

    context "user does not have role" do
      it "raises ArgumentError" do
        lambda {
          @s.remove_role(@user.id, @role1.id)
        }.should raise_error(ArgumentError)
      end
    end

    it "removes role from user" do
      @ruser.has_role?(@role.id).should be_true
      @s.remove_role(@user.id, @role.id)
      @ruser.has_role?(@role.id).should be_false
    end

    it "returns nil" do
      @s.remove_role(@user.id, @role.id).should be_nil
    end
  end

  describe "#add_privilege", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :PERMISSION_METHODS
      @registry = Users::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "not local node" do
      before(:each) do
        # change the node type
        @n.node_type = 'local-test'
      end

      context "insufficient privileges (modify-roles)" do
        it "raises PermissionError" do
          role = create(:role)
          lambda {
            @s.add_privilege(role.id, 'view')
          }.should raise_error(PermissionError)
        end
      end

      context "sufficient privileges (modify-roles)" do
        it "does not raise PermissionError" do
          add_privilege(@login_role, 'modify', 'roles')
          role = create(:role)
          lambda {
            @s.add_privilege(role.id, 'view')
          }.should_not raise_error
        end
      end
    end

    context "role not found" do
      it "raises DataNotFound" do
        lambda {
            @s.add_privilege('nonexistant', 'view')
        }.should raise_error(DataNotFound)
      end
    end

    it "adds privilege to role" do
      role = create(:role)
      @s.add_privilege(role.id, 'view')
      @registry.entity(&with_id(role.id)).
                privileges.collect { |r| [r.id, r.entity_id] }.
                should include(['view', nil])
    end

    it "should allow optional entity" do
      role = create(:role)
      @s.add_privilege(role.id, 'view', 'users')
      @registry.entity(&with_id(role.id)).
                privileges.collect { |r| [r.id, r.entity_id] }.
                should include(['view', 'users'])
    end

    it "returns nil" do
      role = create(:role)
      @s.add_privilege(role.id, 'view').should be_nil
    end

  end # describe #add_privilege

  describe "#remove_privilege", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :PERMISSION_METHODS
      @registry = Users::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)

      @role  = create(:role)
      @rrole = @registry.proxy_for(&with_id(@role.id))
      @rrole.add_privilege('view')
      @rrole.add_privilege('modify', 'ship')
    end

    context "local node" do
      it "does not raise permission error" do
        lambda {
          @s.remove_privilege(@role.id, 'view')
        }.should_not raise_error
      end
    end

    context "not local node" do
      before(:each) do
        # change the node type
        @n.node_type = 'local-test'
      end

      context "insufficient privileges (modify-roles)" do
        it "raises PermissionError" do
          lambda {
            @s.remove_privilege(@role.id, 'view')
          }.should raise_error(PermissionError)
        end
      end

      context "sufficient privileges (modify-roles)" do
        it "does not raise PermissionError" do
          add_privilege(@login_role, 'modify', 'roles')
          lambda {
            @s.remove_privilege(@role.id, 'view')
          }.should_not raise_error
        end
      end
    end

    context "role not found" do
      it "raises DataNotFound" do
        lambda {
          @s.remove_privilege('invalid', 'view')
        }.should raise_error(DataNotFound)
      end
    end

    context "role does not have privilege" do
      it "raises ArgumentError" do
        lambda {
          @s.remove_privilege(@role.id, 'modify')
        }.should raise_error(ArgumentError)
      end
    end

    it "removes privilege from role" do
      @rrole.has_privilege?('view').should be_true
      @s.remove_privilege(@role.id, 'view')
      @rrole.has_privilege?('view').should be_false
    end

    context "entity specified" do
      context "roles does not have privilege on entity" do
        it "raises ArgumentError" do
          lambda {
            @s.remove_privilege(@role.id, 'view', 'ship')
          }.should raise_error(ArgumentError)
        end
      end

      it "removes privilege on entity from role" do
        @rrole.has_privilege_on?('modify', 'ship').should be_true
        @s.remove_privilege(@role.id, 'modify', 'ship')
        @rrole.has_privilege_on?('modify', 'ship').should be_false
      end
    end

    it "returns nil" do
      @s.remove_privilege(@role.id, 'modify', 'ship').should be_nil
    end
  end

  describe "#dispatch_users_rjr_permissions" do
    it "adds users::add_role to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_permissions(d)
      d.handlers.keys.should include("users::add_role")
    end

    it "adds users::remove_role to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_permissions(d)
      d.handlers.keys.should include("users::remove_role")
    end

    it "adds users::add_privilege to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_permissions(d)
      d.handlers.keys.should include("users::add_privilege")
    end

    it "adds users::remove_privilege to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_permissions(d)
      d.handlers.keys.should include("users::remove_privilege")
    end
  end

end #module Users::RJR
