# manufactured::remove_callbacks tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/remove_callbacks'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#remove_callbacks", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured :REMOVE_CALLBACKS_METHODS

      @sh = create(:valid_ship)
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }

      @cb1 = Omega::Server::Callback.new :endpoint_id => 'foobar'
      @cb2  = Omega::Server::Callback.new :endpoint_id => @n.node_id
      @rsh.callbacks << @cb1
      @rsh.callbacks << @cb2

      @registry << Manufactured::EventHandler.new(:event_type  => 'system_jump',
                                                  :endpoint_id => @n.node_id)

      @s.stub(:rjr_env) { Manufactured::RJR }
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

  describe "#dispatch_manufactured_rjr_remove_callbacks" do
    it "adds manufactured::remove_callbacks to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_remove_callbacks(d)
      d.handlers.keys.should include("manufactured::remove_callbacks")
    end

    it "adds manufactured::unsubscribe to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_remove_callbacks(d)
      d.handles?('manufactured::unsubscribe').should be_true
    end
  end

end # module Manufactured::RJR
