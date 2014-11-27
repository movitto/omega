# Omega Client Corvette Tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/corvette'
require 'omega/client/entities/solar_system'

module Omega::Client
  describe Corvette, :rjr => true do
    before(:each) do
      Omega::Client::Corvette.node.rjr_node = @n
      setup_manufactured(nil, reload_super_admin)
    end

    describe "#validatation" do
      it "ensures ship.type == :corvette" do
        s1 = create(:valid_ship, :type => :corvette)
        s2 = create(:valid_ship, :type => :frigate)
        r = Corvette.get_all
        r.size.should == 1
        r.first.id.should == s1.id
      end
    end

    context "initialization" do
      before(:each) do
        @c = Omega::Client::Corvette.new
        @orig = @c.class.class_variable_get(:@@proximity_thread)
        @c.class.class_variable_set(:@@proximity_thread, nil)
      end

      after(:each) do
        @c.class.class_variable_set(:@@proximity_thread, @c)
      end

      it "starts async corvette proximity checker" do
        t = Object.new
        Thread.should_receive(:new).and_return(t)
        @c.class.send :init_entity, @c
        @c.class.class_variable_get(:@@proximity_thread).should == t
      end

      it "periodically checks proximity for all local corvettes"
    end

    describe "#attack" do
      before(:each) do
        c = create(:valid_ship, :type => :corvette)
        @s = create(:valid_ship, :type => :frigate)
        @c = Corvette.get(c.id)
      end

      it "invokes manufactured::attack_entity" do
        @n.should_receive(:invoke).with 'manufactured::attack_entity', @c.id, @s.id
        @c.attack @s
      end
    end

    describe "#start_bot" do
      before(:each) do
        c = create(:valid_ship, :type => :corvette)
        @c = Corvette.get(c.id)
      end

      it "starts listening for destroyed_by events" do
        @c.should_receive(:handle).with(:destroyed_by)
        @c.should_receive(:handle).at_least(:once)
        @c.start_bot
      end

      it "starts patrol route" do
        @c.should_receive(:patrol_route)
        @c.start_bot
      end

      it "handles attacked_stop event" do
        @c.should_receive(:handle).with(:attacked_stop)
        @c.should_receive(:handle).at_least(:once)
        @c.start_bot
      end

      context "attacked_stop" do
        it "resumes patrol route" do
          @c.should_receive(:patrol_route).twice
          @c.start_bot
          @c.raise_event :attacked_stop
        end
      end
    end

    describe "#patrol_route" do
      before(:each) do
        @sys1 = create(:solar_system)
        @sys2 = create(:solar_system)
        @sys3 = create(:solar_system)
        @jg1 = create(:jump_gate, :solar_system => @sys1, :endpoint => @sys2)
        @jg2 = create(:jump_gate, :solar_system => @sys1, :endpoint => @sys3)

        c = create(:valid_ship, :type => :corvette, :solar_system => @sys1)
        @c = Corvette.get(c.id)
        @c.visited = []
      end

      it "adds current system to visited list" do
        @c.patrol_route
        @c.visited.collect { |v| v.id }.should include(@c.solar_system.id)
      end

      context "no jump gates to systems not visited found" do
        it 'resets visited list' do
          @c.visited << @sys2
          @c.visited << @sys3
          @c.visited.collect { |v| v.id }.should == [@sys2.id, @sys3.id]
          @c.patrol_route

          # XXX patrol_route ^ will invoke patrol_route
          # again, adding current system to list
          @c.visited.collect { |v| v.id }.should == [@c.solar_system.id]
        end

        #it "restarts patrol route" do
        #  @c.visited << @sys2
        #  @c.visited << @sys3
        #  @c.should_receive :patrol_route # XXX
        #  @c.patrol_route
        #end
      end

      context "no jump gates to systems not visited found twice in a row" do
        it "raises patrol_err event" do
          @c.solar_system.should_receive(:jump_gates).twice.and_return([])
          @c.should_receive(:raise_event).with(:patrol_err)
          @c.patrol_route
          @c.instance_variable_get(:@patrol_err).should be_true
        end

        it "returns, terminating patrol route" do
          @c.solar_system.should_receive(:jump_gates).twice.and_return([])
          @c.should_receive(:patrol_route).twice.and_call_original
          @c.patrol_route
        end
      end

      it "raises selected_system event" do
        @c.should_receive(:raise_event).with { |e,s,j|
          e.should == :selected_system
          s.should == @sys2.id
          j.id.should == @jg1.id
        }
        @c.patrol_route
      end

      it "clears patrol err" do
        @c.instance_variable_set(:@patrol_err, true)
        @c.patrol_route
        @c.instance_variable_get(:@patrol_err).should be_false
      end

      context "jump gate within triggering distance" do
        it "jumps to next system" do
          @c.location = @jg1.location
          @c.should_receive(:jump_to).
            with(Omega::Client::SolarSystem.cached(@sys2.id)).
            and_raise(Exception) # XXX raise exception to prevent partol_route recursion
          begin
            @c.patrol_route
          rescue Exception
          end
        end

        it "continues patrol route" do
          @c.location = @jg1.location
          @c.should_receive(:patrol_route).once.and_call_original
          @c.stub(:jump_to) {
            @c.rspec_reset
            @c.should_receive(:patrol_route).
              and_raise(Exception) # XXX raise exception to prevent infinite recursion
          }
          begin
            @c.patrol_route
          rescue Exception
          end
        end
      end

      context "jump gate not within triggering distance" do
        it "moves to jump gate" do
          @c.should_receive(:move_to)
          @c.patrol_route
        end

        context "on arrival at jump gate" do
          it 'jumps to next system' do
            @c.should_receive(:jump_to)
            @c.patrol_route
            @c.should_receive(:patrol_route) # stub out additional patrol_route invocations
            @c.raise_event(:movement)
          end

          #it "continues patrol route" do
          #  @c.should_receive(:jump_to)
          #  @c.should_receive(:patrol_route)
          #  @c.patrol_route
          #  @c.raise_event(:movement)
          #end
        end
      end
    end

    describe "#check_proximity" do
      before(:each) do
        c  = create(:valid_ship, :type => :corvette)
        @c = Corvette.get(c.id)
      end

      it "retrieves entities in same system as ship" do
        @c.solar_system.should_receive(:entities).and_return([])
        @c.check_proximity
      end

      context "ship beloning to other user within attacking distance" do
        before(:each) do
          l = build(:location)
          l.coordinates = @c.location.coordinates
          @o = create(:valid_ship, :user_id => create(:user).id,
                                   :location => l, :solar_system => @c.solar_system)
        end

        context "already attacking" do
          it "skips attack" do
            @c.should_receive(:attacking?).and_return(true)
            @c.should_not_receive(:attack)
            @c.check_proximity
          end
        end

        context "not alive" do
          it "skips attack" do
            @c.should_receive(:alive?).and_return(false)
            @c.should_not_receive(:attack)
            @c.check_proximity
          end
        end

        it "stops moving" do
          @c.should_receive(:stop_moving)
          @c.check_proximity
        end

        context "already handling attacked_stop" do
          it "does not register another attacked_stop handler" do
            @c.instance_variable_set(:@check_proximity_handler, true)
            @c.should_not_receive(:handle)
            @c.check_proximity
          end
        end

        it "attacks ship" do
          @c.should_receive(:attack).with{ |*a| a[0].id.should == @o.id }
          @c.check_proximity
        end
      end
    end
  end # describe Corvette
end # module Omega::Client
