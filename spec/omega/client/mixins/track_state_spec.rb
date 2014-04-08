# Omega Client TrackState Mixin tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'ostruct'
require 'omega/client/mixins/track_state'

module Omega::Client
  describe TrackState, :rjr => true do
    before(:each) do
      @t = OmegaTest::Trackable.new
      @t.entity = OpenStruct.new(:id => 42)
      OmegaTest::Trackable.node.rjr_node = @n
      OmegaTest::Trackable.send :init_entity, @t

      setup_manufactured(nil, reload_super_admin)
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
      it "registers new initialization method" do
        # XXX FIXME very hacky way to verify this
        loc  = OmegaTest::Trackable.method(:server_state).source_location.last
        init = OmegaTest::Trackable.instance_variable_get(:@entity_init).
                 collect { |ei| ei.source_location.last == loc + 1}
        init.should_not be_nil
      end

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

end # module Omega::Client
