# manufactured::subscribe_to entity_events helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/subscribe_to/entity_events'

module Manufactured::RJR
  describe "#subscribe_to_entity_event", :rjr => true do
    include Omega::Server::DSL # for with_id below
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :SUBSCRIBE_TO_METHODS
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
            @cb.invoke @rsh
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
          @n.should_receive(:notify).and_raise(Omega::ConnectionError)
          lambda{
            @cb.invoke @rsh
          }.should change{@rsh.callbacks.size}.by(-1)
        end
      end

      context "other error (generic)" do
        it "removes callback from entity" do
          add_privilege @login_role, 'view', 'manufactured_entities'
          @n.should_receive(:notify).and_raise(Exception)
          lambda{
            @cb.invoke @rsh
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
end # module Manufactured::RJR
