# client mixin modules tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'ostruct'
require 'spec_helper'
require 'omega/client/mixins'

# Test data used in this module
module OmegaTest
  class Trackable
    include Omega::Client::Trackable
    include Omega::Client::TrackState
    include Omega::Client::TrackEntity
    entity_type Manufactured::Ship
    get_method "manufactured::get_entity"
  
    server_state :test_state,
      { :check => lambda { |e| @toggled ||= false ; @toggled = !@toggled },
        :on    => lambda { |e| @on_toggles_called  = true },
        :off   => lambda { |e| @off_toggles_called = true } }

    attr_accessor :setup_run

    entity_event :setup_event => { :setup => proc { |e| @setup_run = true } }

    entity_event :subscribe_event => { :subscribe => 'subscribe_method' }

    entity_event :notification_event => { :notification => 'notification_method' }

    entity_event :match_event => { :notification => 'match_method',
                                    :match => proc { |e,*args| false } }

    attr_accessor :entity_initialized
    entity_init{ |e|
      @entity_initialized = true
    }
  end
end

module Omega::Client
  describe Trackable do
    before(:each) do
      @t = OmegaTest::Trackable.new
      OmegaTest::Trackable.node.rjr_node = @n

      setup_manufactured(nil)
      add_role @login_role, :superadmin
    end

    describe "#method_missing" do
      it "dispatches everything to tracked entity" do
        e = stub(:Object)
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
        e = stub(Object)
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
        it "raises event on entity" do
          @t.handle(:match_event) {}
          @t.should_receive(:raise_event).with(:notification_event, :foo)
          m = @t.class.node.handlers['notification_method'].first
          @t.instance_exec :foo, &m
        end

        context "match is false" do
          it "does not raise event" do
            @t.handle(:notification_event) {}
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

  describe TrackState do
    before(:each) do
      @t = OmegaTest::Trackable.new
      @t.entity = OpenStruct.new(:id => 42)
      OmegaTest::Trackable.node.rjr_node = @n
      OmegaTest::Trackable.send :init_entity, @t

      setup_manufactured(nil)
      add_role @login_role, :superadmin
    end

    describe "#on_state" do
      it "registers new on state callback" do
        h = proc {}
        @t.on_state(:test_state, &h)
        # first defined in class above, 2nd here
        @t.instance_variable_get(:@on_state_callbacks)[:test_state].size.should == 2
        @t.instance_variable_get(:@on_state_callbacks)[:test_state].last.should == h
      end
    end

    describe "#off_state" do
      it "registers new off state callback" do
        h = proc {}
        @t.off_state(:test_state, &h)
        # first defined in class above, 2nd here
        @t.instance_variable_get(:@off_state_callbacks)[:test_state].size.should == 2
        @t.instance_variable_get(:@off_state_callbacks)[:test_state].last.should == h
      end
    end

    describe "#set_state" do
      context "state == current state" do
        it "just returns" do
          @t.states << 'cs'
          lambda {
            @t.set_state('cs')
          }.should_not change{@t.states}
        end
      end

      it "pushes state onto of states array" do
        lambda {
          @t.set_state('cs')
        }.should change{@t.states.size}.by(1)
        @t.states.should include('cs')
      end

      it "invokes on_state callbacks" do
        invoked = false
        @t.on_state('cs') { |e|
          invoked = true
        }
        @t.set_state('cs')
        invoked.should be_true
      end
    end

    describe "#unset_state" do
      context "state not in states array" do
        it "just returns" do
          lambda {
            @t.unset_state('cs')
          }.should_not change{@t.states}
        end
      end

      it "removes state from states array" do
        @t.set_state('cs')
        lambda {
          @t.unset_state('cs')
        }.should change{@t.states.size}.by(-1)
        @t.states.should_not include('cs')
      end

      it "invokes off_state callbacks" do
        invoked = false
        @t.off_state('cs') { |e|
          invoked = true
        }
        @t.set_state('cs')
        @t.unset_state('cs')
        invoked.should be_true
      end
    end

    describe "#server_state" do
      it "registers new initialization method"

      context "entity intialization" do
        # entity is initialized via init_entity in TrackState#before(:each)
        before(:each) do
        end

        it "initializes states and state callbacks" do
          @t.states.should == []
          @t.instance_variable_get(:@on_state_callbacks).should be_an_instance_of(Hash)
          @t.instance_variable_get(:@off_state_callbacks).should  be_an_instance_of(Hash)
          @t.instance_variable_get(:@condition_checks).should be_an_instance_of(Hash)
        end

        it "registers specified on/off state callbacks" do
          on  = @t.instance_variable_get(:@on_state_callbacks)
          off = @t.instance_variable_get(:@off_state_callbacks)
          on[:test_state].size.should == 1
          off[:test_state].size.should == 1
        end

        it "registers specified condition checks" do
          cc = @t.instance_variable_get(:@condition_checks)
          cc[:test_state].should_not be_nil
        end

        it "registers callback for all entity events" do
          @t.handles?(:all).should be_true
          @t.event_handlers[:all].size.should == 1
        end
      end

      context "entity event" do
        context "state condition checks match" do
          it "sets state" do
            @t.instance_variable_get(:@condition_checks)[:test_state] = proc { |e| true }
            @t.should_receive(:set_state).with(:test_state)
            @t.raise_event(:anything)
          end
        end

        context "state condition do not match" do
          it "unsets state" do
            @t.instance_variable_get(:@condition_checks)[:test_state] = proc { |e| false }
            @t.should_receive(:unset_state).with(:test_state)
            @t.raise_event(:anything)
          end
        end
      end
    end
  end # describe TrackState

  describe TrackEntity do
    before(:each) do
      OmegaTest::Trackable.node.rjr_node = @n
      setup_manufactured(nil)
      add_role @login_role, :superadmin
    end

    after(:each) do
      OmegaTest::Trackable.clear_entities
    end

    context "entity class initialization" do
      it "initializes entity registry" do
        TrackEntity.entities.should == []
      end
    end

    context "entity initialization" do
      it "registers entity w/ local registry" do
        s = create(:valid_ship)
        t = OmegaTest::Trackable.get(s.id)
        OmegaTest::Trackable.entities.should == [t]
      end

      context "entity w/ id exists" do
        it "deletes old entity" do
          s = create(:valid_ship)
          t1 = OmegaTest::Trackable.get(s.id)
          t2 = OmegaTest::Trackable.get(s.id)
          OmegaTest::Trackable.entities.should == [t2]
        end
      end
    end

    describe "#entities" do
      it "returns entity list" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)
        t1 = OmegaTest::Trackable.get(s1.id)
        t2 = OmegaTest::Trackable.get(s2.id)
        OmegaTest::Trackable.entities.should == [t1, t2]
        t1.entities.should == OmegaTest::Trackable.entities
        t2.entities.should == OmegaTest::Trackable.entities
      end
    end

    describe "#clear_entities" do
      it "clears entities list" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)
        t1 = OmegaTest::Trackable.get(s1.id)
        t2 = OmegaTest::Trackable.get(s2.id)
        OmegaTest::Trackable.clear_entities
        OmegaTest::Trackable.entities.should == []
      end
    end

    describe "TrackEntity#entities" do
      it "returns entities from all TrackEntity subclasses"
    end

    describe "TrackEntity#clear_entities" do
      it "clears entities in all TrackEntity subclasses"
    end
  end
end # module Omega::Client
