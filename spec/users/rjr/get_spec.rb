# users::get_entities tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/get'
require 'rjr/dispatcher'

module Users::RJR
  describe "#get_entities", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :GET_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    it "returns list of all entities" do
      # grant user permissions to view all users types
      add_privilege @login_role, 'view', 'roles'
      add_privilege @login_role, 'view', 'users'
      add_privilege @login_role, 'view', 'sessions'

      create(:user)
      create(:user)
      n = Users::RJR.registry.entities(&in_subsystem).size
      i = Users::RJR.registry.entities(&in_subsystem).collect { |e| e.id }
      s = @s.get_entities
      s.size.should == n
      s.collect { |e| e.id }.should == i
    end

    context "entity id specified" do
      it "returns corresponding entity" do
        u = @s.get_entities 'with_id', @login_user.id
        u.should be_an_instance_of(User)
        u.id.should == @login_user.id
      end

      context "entity not found" do
        it "raises DataNotFound" do
          lambda {
            @s.get_entities 'with_id', 'nonexistant'
          }.should raise_error(DataNotFound)
        end
      end

      context "user does not have view privilege on entity" do
        it "raises PermissionError" do
          u = create(:user)
          lambda {
            @s.get_entities 'with_id', u.id
          }.should raise_error(PermissionError)
        end
      end
    end

    context "entity id not specified" do
      it "filters entities user does not have permission to" do
        # only view privilege on users
        add_privilege @login_role, 'view', 'users'

        u = Users::RJR.registry.entities.select { |e| e.is_a?(User) }
        n = u.size
        @s.get_entities.size.should == n
      end
    end

    context "entity type specified" do
      it "only returns entities of the specified type" do
        # privileges on roles/users
        add_privilege @login_role, 'view', 'roles'
        add_privilege @login_role, 'view', 'users'

        u = Users::RJR.registry.entities.select { |e| e.is_a?(User) }
        n = u.size
        @s.get_entities(:of_type, 'Users::User').size.should == n
      end
    end
  end # describe #get_entities

  describe "#dispatch_users_rjr_get" do
    it "adds users::get_entities to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_get(d)
      d.handlers.keys.should include("users::get_entities")
    end
  end

end #module Users::RJR
