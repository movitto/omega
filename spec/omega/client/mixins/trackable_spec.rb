# Omega Client Trackable Mixin Tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/mixins/trackable'

module Omega::Client
  describe Trackable, :rjr => true do
    before(:each) do
      @t = OmegaTest::Trackable.new
      OmegaTest::Trackable.node.rjr_node = @n

      setup_manufactured(nil, reload_super_admin)
    end

    describe "#refresh" do
      it "refreshes the local entity from the server" do
        s1 = create(:valid_ship)
        r = OmegaTest::Trackable.get(s1.id)
        @n.should_receive(:invoke).with('manufactured::get_entity', 'with_id', s1.id)
        r.refresh
      end
    end

    describe "#method_missing" do
      it "dispatches everything to tracked entity" do
        e = double(:Object)
        e.should_receive :foobar
        @t.entity = e
        @t.foobar
      end
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

    describe "#get_all" do
      it "returns all entities of entity_type" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)
        r = OmegaTest::Trackable.get_all
        r.size.should == 2
        r.all? { |ri| ri.should be_an_instance_of(OmegaTest::Trackable) }
        ids = r.collect { |s| s.id }
        ids.should include(s1.id)
        ids.should include(s2.id)
      end

      it "filters entities that fail validation" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)

        OmegaTest::Trackable.should_receive(:validate_entity).
                             with{|e| e.id == s1.id }.and_return(false)
        OmegaTest::Trackable.should_receive(:validate_entity).
                             with{|e| e.id == s2.id }.and_return(true)

        r = OmegaTest::Trackable.get_all
        r.size.should == 1
        r.first.id.should == s2.id
      end
    end

    describe "#get" do
      it "returns entity with specified id" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)

        r = OmegaTest::Trackable.get(s1.id)
        r.should be_an_instance_of(OmegaTest::Trackable)
        r.id.should == s1.id
      end

      context "validation fails" do
        it "returns nil" do
          s1 = create(:valid_ship)
          OmegaTest::Trackable.should_receive(:validate_entity).
                               with{|e| e.id == s1.id }.and_return(false)
          r = OmegaTest::Trackable.get(s1.id)
          r.should be_nil
        end
      end
    end

    describe "#owned_by" do
      it "returns all entities of type owned by specified user" do
        u1 = create(:user)
        u2 = create(:user)
        s1 = create(:valid_ship, :user_id => u1.id)
        s2 = create(:valid_ship, :user_id => u1.id)
        s3 = create(:valid_ship, :user_id => u2.id)

        r = OmegaTest::Trackable.owned_by(u1.id)
        r.size.should == 2
        ids = r.collect { |s| s.id }
        ids.should include(s1.id)
        ids.should include(s2.id)
      end

      it "filters entities that fail validation" do
        u1 = create(:user)
        u2 = create(:user)
        s1 = create(:valid_ship, :user_id => u1.id)
        s2 = create(:valid_ship, :user_id => u1.id)
        s3 = create(:valid_ship, :user_id => u2.id)

        OmegaTest::Trackable.should_receive(:validate_entity).
                             with{|e| e.id == s1.id }.and_return(false)
        OmegaTest::Trackable.should_receive(:validate_entity).
                             with{|e| e.id == s2.id }.and_return(true)


        r = OmegaTest::Trackable.owned_by(u1.id)
        r.size.should == 1
        ids = r.collect { |s| s.id }
        ids.should include(s2.id)
      end
    end
  end # describe Trackable
end # module Omega::Client
