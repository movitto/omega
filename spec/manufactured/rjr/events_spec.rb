# manufactured::subscribe_to, manufactured::remove_callbacks tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/events'
require 'manufactured/events'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "subsystem_event?" do
    include Manufactured::RJR

    context "Manufactured::Event type" do
      it "returns true" do
        event_type = Manufactured::Events::SystemJump::TYPE.to_s
        subsystem_event?(event_type).should be_true
      end
    end

    context "anything else" do
      it "returns false" do
        subsystem_event?(42).should be_false
      end
    end
  end

  describe "subsystem_entity?" do
    include Manufactured::RJR

    context "ship or station" do
      it "returns true" do
        subsystem_entity?(Manufactured::Ship.new).should be_true
      end
    end

    context "anything else" do
      it "returns false" do
        subsystem_entity?(42).should be_false
      end
    end
  end

  describe "#cosmos_entity?" do
    include Manufactured::RJR

    context "Cosmos::Entity instance" do
      it "returns true" do
        cosmos_entity?(Cosmos::Entities::Galaxy.new).should be_true
      end
    end

    context "anything else" do
      it "returns false" do
        cosmos_entity?(42).should be_false
      end
    end
  end

  describe "#subscribe_to_subsystem_event", :rjr => true do
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :EVENTS_METHODS
      @sh = create(:valid_ship)
    end

    it "adds new persistent event handler for event type to registry" do
      lambda {
        subscribe_to_subsystem_event 'system_jump', 'node1', 'to', 'sys1'
      }.should change{@registry.entities.size}.by(1)

      eh = @registry.entities.last
      eh.event_type.should == 'system_jump'
      eh.persist.should be_true
    end

    it "sets endpoint id on handler" do
      subscribe_to_subsystem_event 'system_jump', 'node1', 'to', 'sys1'
      eh = @registry.entities.last
      eh.endpoint_id.should == 'node1'
    end

    it "sets event args on handler" do
      subscribe_to_subsystem_event 'system_jump', 'node1', 'to', 'sys1'
      eh = @registry.entities.last
      eh.event_args.should == ['to', 'sys1']
    end

    context "handler invoked" do
      before(:each) do
        subscribe_to_subsystem_event 'system_jump', 'node1', 'to', 'sys1'
        @eh = @registry.safe_exec { |entities| entities.last } # direct handle to registry event handler
        @event = Manufactured::Events::SystemJump.new :entity => build(:ship)

        # XXX since we're invoking subscribe_to helper manually,
        # need to setup the required rjr context manually
        @rjr_callback = @n
        @rjr_headers  = @n.message_headers
      end

      context "insufficient permissions on an event arg" do
        it "removes handler from registry" do
          lambda{
            @eh.invoke @event
          }.should change{@registry.entities.size}.by(-1)
        end
      end

      it "sends callback notification via rjr callback" do
        add_privilege @login_role, 'view', 'manufactured_entities'
        @n.should_receive(:notify).with('manufactured::event_occurred', 'system_jump', *@event.event_args)
        @eh.invoke @event
      end

      context "connection error during notification" do
        it "removes handler from registry" do
          add_privilege @login_role, 'view', 'manufactured_entities'
          @n.should_receive(:notify).and_raise(::RJR::Errors::ConnectionError)
          lambda{
            @eh.invoke @event
          }.should change{@registry.entities.size}.by(-1)
        end
      end

      context "other error (generic)" do
        it "removes handler from registry" do
          add_privilege @login_role, 'view', 'manufactured_entities'
          @n.should_receive(:notify).and_raise(Exception)
          lambda{
            @eh.invoke @event
          }.should change{@registry.entities.size}.by(-1)
        end
      end
    end
  end # describe subscribe_to_subsystem_event

  describe "#subscribe_to_entity_event", :rjr => true do
    include Omega::Server::DSL # for with_id below
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :EVENTS_METHODS
      @sh = create(:valid_ship)
      @rsh = @registry.proxy_for &with_id(@sh.id)
    end

    it "creates new callback for event type" do
      lambda{
        subscribe_to_entity_event @sh.id, 'resource_collected', 'node1'
      }.should change{@rsh.callbacks.size}.by(1)
    end

    it "sets rjr method to invoke on callback" do
      subscribe_to_entity_event @sh.id, 'resource_collected', 'node1'
      @rsh.callbacks.last.rjr_event.should == 'manufactured::event_occurred'
    end

    it "sets event type to invoke on callback" do
      subscribe_to_entity_event @sh.id, 'resource_collected', 'node1'
      @rsh.callbacks.last.event_type.should == 'resource_collected'
    end

    it "sets endpoint id on callback" do
      subscribe_to_entity_event @sh.id, 'resource_collected', 'node1'
      @rsh.callbacks.last.endpoint_id.should == 'node1'
    end

    context "callback invoked" do
      before(:each) do
        subscribe_to_entity_event @sh.id, 'resource_collected', 'node1'
        @cb = @rsh.callbacks.last

        # XXX same note as w/ subscribe_to_subsystem_event above
        @rjr_callback = @n
        @rjr_headers  = @n.message_headers
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

    it "removes old callback for event_type/endpoint" do
      c = Omega::Server::Callback.new :event_type  => 'resource_collected',
                                      :endpoint_id => 'node1'
      @rsh.callbacks << c
      @rsh.callbacks.last.should == c
      subscribe_to_entity_event @sh.id, 'resource_collected', 'node1'
      @rsh.callbacks.size.should == 1
      @rsh.callbacks.last.should_not == c
    end

    it "adds new callback for event_type to entity" do
      lambda {
        subscribe_to_entity_event @sh.id, 'resource_collected', 'node1'
      }.should change{@rsh.callbacks.size}.by(1)
      @rsh.callbacks.last.should be_an_instance_of Omega::Server::Callback
    end
  end # describe #subscribe_to_entity_event

  describe "#subscribe_to", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured :EVENTS_METHODS
      @sh = create(:valid_ship)
      @rsh = @registry.proxy_for &with_id(@sh.id)
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

    context "subsystem event" do
      it "subscribes to subsystem event" do
        @s.should_receive(:subscribe_to_subsystem_event).
           with('system_jump', @n.node_id, 'to', 'system1')
        @s.subscribe_to 'system_jump', 'to', 'system1'
      end

      context "rjr connection closed" do
        it "removes deletes event handlers for event type/endpoint" do
          @s.subscribe_to 'system_jump', 'to', 'system1'
          lambda{
            @n.send :connection_event, :closed
          }.should change{@registry.entities.length}.by(-1)
        end
      end
    end

    context "entity event" do
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

      it "subscribes to entity event" do
        @s.should_receive(:subscribe_to_entity_event).
           with(@sh.id, 'resource_collected', @n.node_id)
        @s.subscribe_to @sh.id, 'resource_collected'
      end

      context "rjr connection closed" do
        it "removes callback from entity" do
          @s.subscribe_to @sh.id, 'resource_collected'
          lambda{
            @n.send :connection_event, :closed
          }.should change{@rsh.callbacks.size}.by(-1)
        end
      end
    end

    it "returns nil" do
      r = @s.subscribe_to @sh.id, 'resource_collected'
      r.should be_nil
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

      @registry << Manufactured::EventHandler.new(:event_type  => 'system_jump',
                                                  :endpoint_id => @n.node_id)
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

    context "subsystem event" do
      it "deletes event handler for event type/endpoint from registry" do
        lambda{
          @s.remove_callbacks 'system_jump'
        }.should change{@registry.entities.length}.by(-1)
      end
    end

    context "entity event" do
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
    end

    it "returns nil" do
      add_privilege @login_role, 'view', 'manufactured_entities'
      r = @s.remove_callbacks @sh.id
      r.should be_nil
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

    it "adds manufactured::unsubscribe to dispatcher"
  end

end #module Manufactured::RJR
