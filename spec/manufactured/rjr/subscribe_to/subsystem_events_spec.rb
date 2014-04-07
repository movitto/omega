# manufactured::subscribe_to subsystem_events helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/subscribe_to/subsystem_events'
require 'manufactured/events/system_jump'

module Manufactured::RJR
  describe "#subscribe_to_subsystem_event", :rjr => true do
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :SUBSCRIBE_TO_METHODS
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
        should_receive(:rjr_env).at_least(:once).and_return(Manufactured::RJR)
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
          @n.should_receive(:notify).and_raise(Omega::ConnectionError)
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
end # module Manufactured::RJR
