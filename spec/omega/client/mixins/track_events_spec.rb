# Omega Client TrackEvents Mixin Tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/mixins/trackable'

module Omega::Client
  describe Trackable, :rjr => true do
    before(:each) do
      @t = OmegaTest::Trackable.new
      OmegaTest::Trackable.node.rjr_node = @n

      setup_manufactured(nil, reload_super_admin)
    end

    describe "#handle" do
      it "registers new event handler" do
        h = proc {}
        @t.handle(:foo, &h)
        @t.event_handlers[:foo].size.should == 1
        @t.event_handlers[:foo].first.should == h
      end

      it "runs event setup callbacks" do
        @t.handle(:setup_event) {}
        @t.setup_run.should be_true
      end
    end

    describe "#handles?" do
      context "entity handles event" do
        it "returns true" do
          @t.handle(:setup_event) {}
          @t.handles?(:setup_event).should be_true
        end
      end

      context "entity does not handle event" do
        it "returns false" do
          @t.handles?(:setup_event).should be_false
        end
      end
    end

    describe "#clear_handlers" do
      it "clears handlers for all events" do
        @t.handle(:foo) {}
        @t.handles?(:foo).should be_true
        @t.clear_handlers
        @t.handles?(:foo).should be_false
      end
    end

    describe "#clear_handlers_for" do
      it "clears handlers for the specified event" do
        @t.handle(:setup_event) {}
        @t.handle(:foo) {}
        @t.clear_handlers_for :foo
        @t.handles?(:foo).should be_false
        @t.handles?(:setup_event).should be_true
      end
    end

    describe "#raise_event" do
      it "invokes registered event handlers" do
        h = proc {}
        @t.handle(:setup_event, &h)

        h.should_receive(:call).with(@t, 42)
        @t.raise_event :setup_event, 42
      end

      it "invokes registered 'all' event handlers" do
        h = proc {}
        @t.handle(:all, &h)

        h.should_receive(:call).with(@t, 42)
        @t.raise_event :anything, 42
      end

      context "error during handlers" do
        it "catches exception / continues gracefully" do
          @t = OmegaTest::Trackable.get(create(:valid_ship).id)

          h = proc { raise Exception, "pwnd" }
          h.should_receive(:call).exactly(2).times.and_call_original

          @t.handle(:foo, &h)
          @t.handle(:all, &h)
          lambda {
            @t.raise_event :foo
          }.should_not raise_error
        end
      end
    end

    describe "#entity_init" do
      it "registers entity initialization method" do
        # one for track_state, one for track entity, and one in class above
        @t.class.entity_init.size.should ==  3
      end

      context "entity intialization" do
        it "invokes registered methods" do
          @t.class.send :init_entity, @t
          @t.entity_initialized.should be_true
        end
      end
    end

    describe "#entity_event" do
      it "registers setup method" do
        @t.class.event_setup[:setup_event].first.should_not be_nil
        m = @t.class.event_setup[:setup_event].first
        @t.instance_exec &m
        @t.setup_run.should be_true
      end

      it "registers subscription base setup method" do
        e = double(Object)
        e.should_receive(:id).and_return(42)
        @t.entity = e

        @n.should_receive(:invoke).with('subscribe_method', 42, :subscribe_event)
        @t.class.event_setup[:subscribe_event].first.should_not be_nil
        m = @t.class.event_setup[:subscribe_event].first
        @t.instance_exec &m
      end

      it "registers notification based setup method" do
        @t.class.node.should_receive(:handle).with('notification_method').and_call_original
        @t.class.event_setup[:notification_event].should_not be_nil
        m = @t.class.event_setup[:notification_event].first
        @t.instance_exec &m
      end

      it "only registers notification handler once" do # per event
        @t.class.node.should_receive(:handle).with('notification_method').once.and_call_original
        @t.class.event_setup[:notification_event].should_not be_nil
        m = @t.class.event_setup[:notification_event].first
        @t.instance_exec &m
        @t.instance_exec &m
      end

      context "notification handler invoked" do
        before(:each) do
          e = double(Object)
          @t.entity = e
        end

        context "update callback is set" do
          it "invokes update callback" do
            @t.handle(:notification_event) {}
            m = @t.class.node.handlers['notification_method'].first
            @t.instance_exec :foo, &m
            @t.updated.should be_true
          end
        end

        it "raises event on entity" do
          @t.handle(:notification_event) {}
          @t.should_receive(:raise_event).with(:notification_event, :foo)
          m = @t.class.node.handlers['notification_method'].first
          @t.instance_exec :foo, &m
        end

        it "serializes entity events" do
          m = nil
          @t.handle(:notification_event) {
            lambda {
              @t.instance_exec :foo, &m
            }.should raise_error(ThreadError)
          }
          m = @t.class.node.handlers['notification_method'].first
          @t.instance_exec :foo, &m
        end

        context "match is false" do
          it "does not raise event" do
            @t.handle(:match_event) {}
            @t.should_not_receive(:raise_event)
            m = @t.class.node.handlers['match_method'].first
            @t.instance_exec :foo, &m
          end
        end
      end
    end

  end
end
