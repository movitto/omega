# users::login, users::logout tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/session'
require 'rjr/dispatcher'

module Users::RJR
  describe "#login", :rjr => true do
    before(:each) do
      dispatch_to @s, Users::RJR, :SESSION_METHODS
    end

    context "user not specified" do
      it "raises ValidationError" do
        lambda {
          @s.login 42
        }.should raise_error(ValidationError)
      end
    end

    context "user not found" do
      it "raises DataNotFound" do
        lambda {
          @s.login User.new(:id => 'nonexistant')
        }.should raise_error(DataNotFound)
      end
    end

    context "login is not valid" do
      it "raises ArgumentError" do
        u = create(:user)
        lambda { 
          @s.login User.new(:id => u.id, :password => 'invalid')
        }.should raise_error(ArgumentError)
      end
    end

    it "delegates to registry to create session" do
      u = create(:user)
      Users::RJR.registry.should_receive(:create_session).and_call_original
      @s.login(u)
    end

    it "returns session" do
      u = create(:user)
      s = @s.login(u)
      s.should be_an_instance_of(Session)
      s.user.id.should == u.id
    end
  end # describe #login

  describe "#logout", :rjr => true do
    before(:each) do
      dispatch_to @s, Users::RJR, :SESSION_METHODS
    end

    context "user not found" do
      it "raises DataNotFound" do
        lambda {
          @s.logout 'nonexistant'
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient privileges (modify-users)" do
      it "raises PermissionError" do
        u = create(:user)
        s = @s.login(u)
        session_id nil # set invalid session so privs wont be picked up
        lambda {
          @s.logout s.id
        }.should raise_error(PermissionError)
      end
    end

    it "delegates to registry to destroy session" do
      u = create(:user)
      s = @s.login(u)
      session_id s.id
      Users::RJR.registry.should_receive(:destroy_session).and_call_original
      @s.logout s.id
    end

    it "returns nil" do
      u = create(:user)
      s = @s.login(u)
      session_id s.id
      @s.logout(s.id).should be_nil
    end
    
  end # describe #logout

  describe "#dispatch_users_rjr_session" do
    it "adds users::login to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_session(d)
      d.handlers.keys.should include("users::login")
    end

    it "adds users::logout to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_session(d)
      d.handlers.keys.should include("users::logout")
    end
  end

end # module Users::RJR
