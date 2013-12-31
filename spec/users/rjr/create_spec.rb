# users::create_user, users::create_role tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/create'
require 'rjr/dispatcher'

module Users::RJR
  describe "#create_user", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :CREATE_METHODS
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

      context "insufficient privileges (create-users)" do
        it "raises PermissionError" do
          new_user = build(:user)
          lambda {
            @s.create_user(new_user)
          }.should raise_error(PermissionError)
        end
      end

      context "sufficient privileges (create-users)" do
        it "does not raise PermissionError" do
          add_privilege(@login_role, 'create', 'users')
          new_user = build(:user)
          lambda {
            @s.create_user(new_user)
          }.should_not raise_error()
        end
      end
    end

    context "non-user specified" do
      it "raises ValidationError" do
        lambda {
          @s.create_user(42)
        }.should raise_error(ValidationError)
      end
    end

    context "role could not be created" do
      it "raises OperationError" do
        new_user = build(:user)
        create(:role, :id => "user_role_#{new_user.id}")
        lambda {
          @s.create_user(new_user)
        }.should raise_error(OperationError)
      end
    end

    context "existing user-id specified" do
      it "raises OperationError" do
        new_user = create(:user)
        lambda {
          @s.create_user(new_user)
        }.should raise_error(OperationError)
      end
    end

    it "sets up base user attributes"

    it "creates new user and user-role in registry" do
      new_user = build(:user)
      lambda {
        @s.create_user(new_user)
      }.should change{@registry.entities.size}.by(2)
      @registry.entity(&with_id(new_user.id)).should_not be_nil
      @registry.entity(&with_id('user_role_' + new_user.id)).should_not be_nil
    end

    it "adds view-user-<user_id> to user's role" do
      new_user = build(:user)
      @s.create_user(new_user)
      @registry.entity(&with_id('user_role_' + new_user.id)).
        has_privilege_on?('view', 'user-' + new_user.id).should be_true
    end

    it "adds modify-user-<user_id> to user's role" do
      new_user = build(:user)
      @s.create_user(new_user)
      @registry.entity(&with_id('user_role_' + new_user.id)).
        has_privilege_on?('modify', 'user-' + new_user.id).should be_true
    end

    it "returns user" do
      new_user = build(:user)
      r = @s.create_user(new_user)
      r.should be_an_instance_of(User)
      r.id.should == new_user.id
    end

  end # describe "#create_user"

  describe "#create_role", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :CREATE_METHODS
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

      context "insufficient privileges (create-roles)" do
        it "raises PermissionError" do
          new_role = build(:role)
          lambda {
            @s.create_role(new_role)
          }.should raise_error(PermissionError)
        end
      end

      context "sufficient privileges (create-roles)" do
        it "does not raise PermissionError" do
          add_privilege(@login_role, 'create', 'roles')
          new_role = build(:role)
          lambda {
            @s.create_role(new_role)
          }.should_not raise_error()
        end
      end
    end

    context "non-role specified" do
      it "raises ValidationError" do
        lambda {
          @s.create_role(42)
        #}.should raise_error(ValidationError)
        }.should raise_error(Exception)
      end
    end

    context "existing user-id specified" do
      it "raises OperationError" do
        existing_role = # TODO
        lambda {
          @s.create_role(existing_role)
        #}.should raise_error(OperationERror)
        }.should raise_error(Exception)
      end
    end

    it "creates new role in registry" do
      new_role = build(:role)
      lambda {
        @s.create_role(new_role)
      }.should change{@registry.entities.size}.by(1)
      @registry.entity(&with_id(new_role.id)).should_not be_nil
    end

    it "returns user" do
      new_role = build(:role)
      r = @s.create_role(new_role)
      r.should be_an_instance_of(Role)
      r.id.should == new_role.id
    end
  end # describe #create_role

  describe "#dispatch_users_rjr_create" do
    it "adds users::create_user to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_create(d)
      d.handlers.keys.should include("users::create_user")
    end

    it "adds users::create_role to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_create(d)
      d.handlers.keys.should include("users::create_role")
    end
  end

end #module Users::RJR
