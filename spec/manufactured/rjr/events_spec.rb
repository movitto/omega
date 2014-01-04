# manufactured::subscribe_to, manufactured::remove_callbacks tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/events'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#subscribe_to", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Manufactured::RJR, :EVENTS_METHODS
      @registry = Manufactured::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)

      # add users, motel, and cosmos modules, initialze manu module
      @n.dispatcher.add_module('users/rjr/init')
      @n.dispatcher.add_module('motel/rjr/init')
      @n.dispatcher.add_module('cosmos/rjr/init')
      dispatch_manufactured_rjr_init(@n.dispatcher)

      @sh = create(:valid_ship)
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }
    end

    context "invalid entity id/type" do
      it "raises DataNotFound" do
        lambda {
          @s.subscribe_to 'invalid', 'resource_collected'
        }.should raise_error(DataNotFound)

        lt = create(:valid_loot)
        lambda {
          @s.subscribe_to lt.id, 'resource_collected'
        }.should raise_error(DataNotFound)
      end
    end

    context "rjr transport is not persistent" do
      it "raises an OperationError" do
        @n.should_receive(:persistent?).and_return(false)
        lambda{
          @s.subscribe_to @sh.id, 'resource_collected'
        }.should raise_error(OperationError)
      end
    end

    context "invalid source node" do
      it "raises a PermissionError" do
        source_node 42
        lambda{
          @s.subscribe_to @sh.id, 'resource_collected'
        }.should raise_error(PermissionError)
      end
    end

    context "source node / session source mismatch" do
      it "raises a PermissionError" do
        source_node 'mismatch'
        lambda{
          @s.subscribe_to @sh.id, 'resource_collected'
        }.should raise_error(PermissionError)
      end
    end

    it "creates new callback for event type" do
      lambda{
        @s.subscribe_to @sh.id, 'resource_collected'
      }.should change{@rsh.callbacks.size}.by(1)
    end

    it "sets rjr method to invoke on callback" do
      @s.subscribe_to @sh.id, 'resource_collected'
      @rsh.callbacks.last.rjr_event.should == 'manufactured::event_occurred'
    end

    it "sets event type to invoke on callback" do
      @s.subscribe_to @sh.id, 'resource_collected'
      @rsh.callbacks.last.event_type.should == 'resource_collected'
    end

    it "sets endpoint id on callback" do
      @s.subscribe_to @sh.id, 'resource_collected'
      @rsh.callbacks.last.endpoint_id.should == @n.node_id
    end

    context "callback invoked" do
      before(:each) do
        @s.subscribe_to @sh.id, 'resource_collected'
        @cb = @rsh.callbacks.last

        @s.instance_variable_set(:@rjr_callback, @n)
      end

      context "insufficient permissions (view-entity)" do
        it "removes callback from entity" do
          lambda{
            @cb.invoke @sh
          }.should change{@rsh.callbacks.size}.by(-1)
        end
      end

      it "send callback notification via rjr callback" do
        add_privilege @login_role, 'view', 'manufactured_entities'
        @n.should_receive(:notify).with('manufactured::event_occurred', 'resource_collected', @sh)
        @cb.invoke @sh
      end

      context "connection error during notification" do
        it "removes callback from entity" do
          add_privilege @login_role, 'view', 'manufactured_entities'
          @n.should_receive(:notify).and_raise(::RJR::Errors::ConnectionError)
          lambda{
            @cb.invoke @sh
          }.should change{@rsh.callbacks.size}.by(-1)
        end
      end

      context "other error (generic)" do
        it "removes callback from entity" do
          add_privilege @login_role, 'view', 'manufactured_entities'
          @n.should_receive(:notify).and_raise(Exception)
          lambda{
            @cb.invoke @sh
          }.should change{@rsh.callbacks.size}.by(-1)
        end
      end
    end

    context "rjr connection closed" do
      it "removes callback from entity" do
        @s.subscribe_to @sh.id, 'resource_collected'
        lambda{
          @n.send :connection_event, :closed
        }.should change{@rsh.callbacks.size}.by(-1)
      end
    end

    it "removes old callback for event_type/endpoint" do
      c = Omega::Server::Callback.new :event_type  => 'resource_collected',
                                      :endpoint_id => @n.node_id
      @rsh.callbacks << c
      @rsh.callbacks.last.should == c
      @s.subscribe_to @sh.id, 'resource_collected'
      @rsh.callbacks.size.should == 1
      @rsh.callbacks.last.should_not == c
    end

    it "adds new callback for event_type to entity" do
      lambda {
        @s.subscribe_to @sh.id, 'resource_collected'
      }.should change{@rsh.callbacks.size}.by(1)
      @rsh.callbacks.last.should be_an_instance_of Omega::Server::Callback
    end

    it "returns entity" do
      r = @s.subscribe_to @sh.id, 'resource_collected'
      r.should be_an_instance_of(Ship)
      r.id.should == @sh.id
    end
  end # describe #subscribe_to

  describe "#remove_callbacks", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured :EVENTS_METHODS

      @sh = create(:valid_ship)
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }

      @cb1 = Omega::Server::Callback.new :endpoint_id => 'foobar'
      @cb2  = Omega::Server::Callback.new :endpoint_id => @n.node_id
      @rsh.callbacks << @cb1
      @rsh.callbacks << @cb2
    end

    context "invalid source node" do
      it "raises a PermissionError" do
        source_node 42
        lambda {
          @s.remove_callbacks @sh.id
        }.should raise_error(PermissionError) # TODO verify message to ensure err was caused by invalid source?
      end
    end

    context "source node / session source mismatch" do
      it "raises a PermissionError" do
        source_node 'mismatch'
        lambda {
          @s.remove_callbacks @sh.id
        }.should raise_error(PermissionError) # TODO verify message to ensure err was cause by mismatch?
      end
    end

    context "invalid entity id/type" do
      it "raises DataNotFound" do
        lambda {
          @s.remove_callbacks 'invalid'
        }.should raise_error(DataNotFound)

        lt = create(:valid_loot)
        lambda {
          @s.remove_callbacks lt.id
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient permissions (view-entity)" do
      it "raises PermissionError" do
        lambda {
          @s.remove_callbacks @sh.id
        }.should raise_error(PermissionError)
      end
    end

    it "removes callbacks for endpoint request came in on" do
      add_privilege @login_role, 'view', 'manufactured_entities'
      lambda {
        @s.remove_callbacks @sh.id
      }.should change{@rsh.callbacks.size}.by(-1)
      @rsh.callbacks.last.endpoint_id.should_not == @n.node_id
    end

    it "returns entity" do
      add_privilege @login_role, 'view', 'manufactured_entities'
      r = @s.remove_callbacks @sh.id
      r.should be_an_instance_of Ship
      r.id.should == @sh.id
    end

  end # describe remove_callbacks

  describe "#dispatch_manufactured_rjr_events" do
    it "adds manufactured::subscribe_to to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_events(d)
      d.handlers.keys.should include("manufactured::subscribe_to")
    end

    it "adds manufactured::remove_callbacks to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_events(d)
      d.handlers.keys.should include("manufactured::remove_callbacks")
    end
  end

end #module Manufactured::RJR
