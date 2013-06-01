# users::update_attribute, users::has_attribute tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/attribute'
require 'rjr/dispatcher'

module Users::RJR
  describe "#update_attribute" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :ATTRIBUTE_METHODS
      @registry = Users::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password

      @attr = OmegaTest::Attribute.id

      @o = Users::RJR.user_attrs_enabled 
      Users::RJR.user_attrs_enabled = true
    end

    after(:each) do
      Users::RJR.user_attrs_enabled = @o
    end

    context "not local node" do
      it "raises PermissionError" do
        @n.node_type = 'local-test'
        lambda {
          @s.update_attribute 'any', 'thi', 'ng'
        }.should raise_error(PermissionError)
      end
    end

    context "insufficient privileges (modify-user_attributes)" do
      it "raises PermissionError" do
        lambda {
          @s.update_attribute @login_user.id, @attr, 1
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges (modify-user_attributes)" do
      before(:each) do
        add_privilege 'user_role_' + @login_user.id, 'modify', 'user_attributes'
      end

      context "user id not found" do
        it "raises DataNotFound" do
          lambda {
            @s.update_attribute 'non-existant', @attr, 1
          }.should raise_error(DataNotFound)
        end
      end
  
      context "insufficient privileges (modify-users)" do
        it "raises PermissionError" do
          u = create(:user)
          lambda {
            @s.update_attribute u.id, @attr, 1
          }.should raise_error(PermissionError)
        end
      end
  
      context "user attributes disabled" do
        before(:each) do
          @o = Users::RJR.user_attrs_enabled 
          Users::RJR.user_attrs_enabled = false
        end

        after(:each) do
          Users::RJR.user_attrs_enabled = @o
        end

        it "skips updating attribute" do
          Users::RJR.registry.should_not_receive(:update)
          @s.update_attribute @login_user.id, @attr, 1
        end
      end
  
      it "updates attribute in registry" do
        @s.update_attribute @login_user.id, @attr, 1
        u = Users::RJR.registry.entity &with_id(@login_user.id)
        u.has_attribute?(@attr, 1).should be_true
      end
  
      it "returns user" do
        r = @s.update_attribute @login_user.id, @attr, 1
  
        r.should be_an_instance_of(User)
        r.id.should == @login_user.id
      end
    end

  end # describe "#update_attribute"

  describe "#has_attribute" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :ATTRIBUTE_METHODS
      @registry = Users::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password

      @attr = OmegaTest::Attribute.id.to_s

      @o = Users::RJR.user_attrs_enabled 
      Users::RJR.user_attrs_enabled = true
    end

    after(:each) do
      Users::RJR.user_attrs_enabled = @o
    end

    context "level not specified" do
      it "sets level to 0"
    end

    context "invalid user id" do
      it "raises ArgumentError" do
        lambda {
          @s.has_attribute(:invalid, @attr)
        }.should raise_error(ArgumentError)
      end
    end

    context "invalid attr_id" do
      it "raises ArgumentError" do
        lambda {
          @s.has_attribute(@login_user.id, :invalid)
        }.should raise_error(ArgumentError)
      end
    end

    context "invalid level" do
      it "raises Argument Error" do
        lambda {
          @s.has_attribute(@login_user.id, @attr, nil)
        }.should raise_error(ArgumentError)

        lambda {
          @s.has_attribute(@login_user.id, @attr,  -1)
        }.should raise_error(ArgumentError)
      end
    end

    context "user id not found" do
      it "raises DataNotFound" do
        u = build(:user)
        lambda {
          @s.has_attribute(u.id, @attr)
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient privileges (view-users)" do
      it "raises PermissionError" do
        u = create(:user)
        lambda {
          @s.has_attribute(u.id, @attr)
        }.should raise_error(PermissionError)
      end
    end

    context "user attributes disabled" do
      before(:each) do
        @o = Users::RJR.user_attrs_enabled 
        Users::RJR.user_attrs_enabled = false
      end

      after(:each) do
        Users::RJR.user_attrs_enabled = @o
      end

      it "always returns true" do
        @s.has_attribute(@login_user.id, @attr).should be_true
      end
    end

    it "returns value of user.has_attribute?" do
      add_privilege 'user_role_' + @login_user.id, 'modify', 'user_attributes'
      @s.update_attribute @login_user.id, @attr, 1
      @s.has_attribute(@login_user.id, @attr   ).should be_true
      @s.has_attribute(@login_user.id, @attr, 2).should be_false
      @s.has_attribute(@login_user.id, 'bar'  ).should be_false
    end

  end # describe #has_role

  describe "#dispatch_attribute" do
    it "adds users::update_attribute to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_attribute(d)
      d.handlers.keys.should include("users::update_attribute")
    end

    it "adds users::has_attribute? to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_attribute(d)
      d.handlers.keys.should include("users::has_attribute?")
    end
  end

end #module Users::RJR
