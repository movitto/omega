# users::send_message, users::subscribe_to_messages,
# users::get_messages tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/chat'
require 'rjr/dispatcher'

module Users::RJR
  describe "#send_message" do
    before(:each) do
      dispatch_to @s, Users::RJR, :CHAT_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "invalid message" do
      it "raises ArgumentError" do
        lambda{
          @s.send_message :invalid
        }.should raise_error(ArgumentError)
      end
    end

    #context "insufficient privileges (modify-users)" do
    #  it "raises PermissionError" do
    #    # FIXME howto test: logged in user needs to not have modify on self
    #    lambda {
    #      @s.send_message "foobar"
    #    }.should raise_error(PermissionError)
    #  end
    #end

    it "sends message" do
      @s.send_message "foobar"
      ChatProxy.proxy_for(@login_user.id).messages.should include("foobar")
    end

    it "returns nil" do
      @s.send_message("foobar").should == nil
    end

  end # describe "#send_message"

  ## FIXME will this work w/ login_user?
  #describe "#subscribe_to_messages" do
  #  include Omega::Server::DSL # for with_id below

  #  before(:each) do
  #    dispatch_to @s, Users::RJR, :CHAT_METHODS

  #    @login_user = create(:user)
  #    @login_role = 'user_role_' + @login_user.id
  #    @s.login @n, @login_user.id, @login_user.password
  #  end

  #  it "adds callback to chat proxy" do
  #    lambda {
  #      @s.subscribe_to_messages
  #    }.should_change{ChatProxy.class_variable_get(:@@proxies).size}.by(1)
  #  end

  #  context "insufficient privileges (view-users)" do
  #    it "removed callback"
  #  end

  #  it "dispatches chat messages to client"

  #  it "returns nil" do
  #    @s.subscribe_to_messages.should be_nil
  #  end

  #end # describe #subscribe_to_messages

  describe "#get_messages" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :CHAT_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    #context "insufficient privileges (view-users)" do
    #  it "raises PermissionError" do
    #    # FIXME howto test: logged in user needs to not have modify on self
    #    lambda {
    #      @s.get_messages
    #    }.should raise_error(PermissionError)
    #  end
    #end

    it "returns user messages" do
      @s.send_message "foobar"
      @s.send_message "barfoo"
      r = @s.get_messages
      r.should == ['foobar', 'barfoo']
    end

  end # describe #get_messages

  describe "#dispatch_users_rjr_chat" do
    it "adds users::send_message to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_chat(d)
      d.handlers.keys.should include("users::send_message")
    end

    it "adds users::get_messages to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_chat(d)
      d.handlers.keys.should include("users::get_messages")
    end

    it "adds users::subscribe_to_messages to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_chat(d)
      d.handlers.keys.should include("users::subscribe_to_messages")
    end
  end

end #module Users::RJR
