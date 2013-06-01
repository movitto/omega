# users::update_user test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/update'
require 'rjr/dispatcher'

module Users::RJR
  describe "#update_user" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :UPDATE_METHODS
      @registry = Users::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
    end

    context "parameter not an instance of user" do
      it "raises ValidationError" do
        lambda {
          @s.update_user 42
        }.should raise_error(ValidationError)
      end
    end

    context "user is invalid" do
      it "raises ValidationError" do
        lambda{
          @s.update_user User.new(:id => :invalid)
        }.should raise_error(ValidationError)
      end
    end

    context "user cannot be found" do
      it "raises DataNotFound" do
        n = build(:user)
        lambda {
          @s.update_user n
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient privileges (modify-users)" do
      it "raises PermissionError" do
        n = create(:user)
        lambda {
          @s.update_user n
        }.should raise_error(PermissionError)
      end
    end

    it "updates user in registry" do
      @login_user.secure_password = false
      @login_user.password = 'foobar'
      @s.update_user @login_user
      Users::RJR.registry.
        entity(&matching{|e| e.is_a?(User) &&
                             e.valid_login?(e.id, 'foobar')
                }).should_not be_nil
    end

    it "only allows password to be updated" do
      # set server-side registration code to
      # ensure it can be nullified
      Users::RJR.registry.update User.new(:id => @login_user.id,
                                          :registration_code => :foo),
                                 &with_id(@login_user.id)

      r = build(:role)
      @login_user.roles = [r]
      @login_user.registration_code = nil
      @s.update_user @login_user

      u = Users::RJR.registry.
            entity(&matching{ |e|
              e.is_a?(User) &&
              e.roles.find { |ro| ro.id == r.id }.nil? &&
              e.registration_code == :foo
            }).should_not be_nil
    end

    it "return user" do
      @s.update_user(@login_user).id.should == @login_user.id
    end

  end # describe "#update_user"

  describe "#dispatch_update" do
    it "adds users::update_user to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_update(d)
      d.handlers.keys.should include("users::update_user")
    end
  end

end #module Users::RJR
