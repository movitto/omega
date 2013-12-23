# users::subscribe_to, users::unsubscribe tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/events'
require 'rjr/dispatcher'

module Users::RJR
  describe "#delete_handler_for" do
    include Users::RJR

    it "removes registry handler for specified event/endpoint" do
      registry = Users::Registry.new
      registry << Omega::Server::EventHandler.new(:event_id => 'registered_user',
                                                  :endpoint_id => 'node1')
      registry.entities.size.should == 1
      delete_handler_for :event => 'registered_user',
                         :endpoint_id => 'node1',
                         :registry => registry
      registry.entities.should be_empty
    end
  end

  describe "#subscribe_to", :rjr => true do
    before(:each) do
      dispatch_to @s, Users::RJR, :EVENTS_METHODS
      @registry = Users::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)

      # add user module
      @n.dispatcher.add_module('users/rjr/init')

      @u = create(:user)
    end

    it "creates new persistant event handler for event/endpoint to registry" do
      lambda{
        @s.subscribe_to 'registered_user'
      }.should change{@registry.entities.size}.by(1)
      handler = @registry.entities.last
      handler.should be_an_instance_of(Omega::Server::EventHandler)
      handler.endpoint_id.should == @n.node_id
      handler.persist.should be_true
      handler.event_id.should == 'registered_user'
    end

    context "handler invoked" do
      before(:each) do
        @s.subscribe_to 'registered_user'
        @handler = @registry.safe_exec { |entities| entities.last }

        @s.instance_variable_set(:@rjr_callback, @n)
        @event = Missions::Events::Users.new :users_event_args => [@u]
      end

      context "insufficient permissions (view-users_events)" do
        it "deletes handler from registry" do
          lambda {
            @handler.invoke @event
          }.should change{@registry.entities.size}.by(-1)
        end
      end

      it "sends notification of users::event_occurred via rjr callback" do
        add_privilege @login_role, 'view', 'users_events'
        @n.should_receive(:notify).with('users::event_occurred', 'registered_user', @u)
        @handler.invoke @event
      end

      context "connection error during notification" do
        it "deletes handler from registry" do
          add_privilege @login_role, 'view', 'users_events'
          @n.should_receive(:notify).and_raise(::RJR::Errors::ConnectionError)
          lambda{
            @handler.invoke @event
          }.should change{@registry.entities.size}.by(-1)
        end
      end

      context "other error (generic)" do
        it "deletes handler from registry" do
          add_privilege @login_role, 'view', 'users_events'
          @n.should_receive(:notify).and_raise(Exception)
          lambda{
            @handler.invoke @event
          }.should change{@registry.entities.size}.by(-1)
        end
      end
    end

    context "rjr connection closed" do
      it "deletes handler from registry" do
        @s.subscribe_to 'registered_user'
        lambda {
          @n.send :connection_event, :closed
        }.should change{@registry.entities.size}.by(-1)
      end
    end

    it "returns nil" do
      @s.subscribe_to('registered_user').should be_nil
    end
  end

  describe "#unsubscribe", :rjr => true do
    before(:each) do
      dispatch_to @s, Users::RJR, :EVENTS_METHODS
      @registry = Users::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)

      eh1 = Omega::Server::EventHandler.new(:event_id => 'registered_user',
                                            :endpoint_id => @n.node_id)
      eh2 = Omega::Server::EventHandler.new(:event_id => 'foo',
                                            :endpoint_id => @n.node_id)
      eh3 = Omega::Server::EventHandler.new(:event_id => 'registered_user',
                                            :endpoint_id => 'randnode')
      @registry << eh1
      @registry << eh2
      @registry << eh3
    end

    context "insufficient permissions (view-users_events)" do
      it "raises PermissionError" do
        lambda{
          @s.unsubscribe 'registered_user'
        }.should raise_error(PermissionError)
      end
    end

    it "deletes handler for event/endpoint from registry" do
      add_privilege @login_role, 'view', 'users_events'
      lambda{
        @s.unsubscribe 'registered_user'
      }.should change{@registry.entities.length}.by(-1)
      @registry.entity { |e| e.is_a?(Omega::Server::EventHandler) &&
                             e.event_id == 'registered_user' &&
                             e.endpoint_id == @n.node_id }.should be_nil
    end

    it "returns nil" do
      add_privilege @login_role, 'view', 'users_events'
      @s.unsubscribe('registered_user').should be_nil
    end
  end

  describe "#dispatch_users_rjr_events" do
    it "adds users::subscribe_to to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_events(d)
      d.handlers.keys.should include("users::subscribe_to")
    end

    it "adds users::unsubscribe to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_events(d)
      d.handlers.keys.should include("users::unsubscribe")
    end
  end
end # module Users::RJR
