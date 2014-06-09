# manufactured::subscribe_to tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/subscribe_to'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#subscribe_to", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured :SUBSCRIBE_TO_METHODS
      @sh = create(:valid_ship)
      @rsh = @registry.proxy_for &with_id(@sh.id)

      @s.stub(:rjr_env) { Manufactured::RJR }
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

  describe "#dispatch_manufactured_rjr_subscribe_to" do
    it "adds manufactured::subscribe_to to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_subscribe_to(d)
      d.handlers.keys.should include("manufactured::subscribe_to")
    end
  end
end # module Manufactured::RJR
