# Omega Client Corvette Tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/corvette'

module Omega::Client
  describe Corvette, :rjr => true do
    before(:each) do
      Omega::Client::Corvette.node.rjr_node = @n
      @m = Omega::Client::Corvette.new

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
      it "starts async corvette proximity checker"
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
        @c.start_bot
      end

      it "starts patrol route" do
        @c.should_receive(:patrol_route)
        @c.start_bot
      end
    end

    describe "#patrol_route" do
      before(:each) do
        @sys1 = create(:solar_system)
        @sys2 = create(:solar_system)
        @sys3 = create(:solar_system)
        jg1 = create(:jump_gate, :solar_system => @sys1, :endpoint => @sys2)
        jg2 = create(:jump_gate, :solar_system => @sys1, :endpoint => @sys3)

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
        it "raises patrol_err event"
        it "returns, terminating patrol route"
      end

      it "raises selected_system event"

      context "jump gate within triggering distance" do
        it "jumps to next system"
        it "continues patrol route"
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

      it "retrieves entities in same system as ship"

      context "ship beloning to other user within attacking distance" do
        before(:each) do
          l = build(:location)
          l.coordinates = @c.location.coordinates
          @o = create(:valid_ship, :user_id => create(:user).id,
                                   :location => l, :solar_system => @c.solar_system)
        end

        context "already attacking or not alive" do
          it "skips attack"
        end

        it "stops moving" do
          @c.should_receive(:stop_moving)
          @c.check_proximity
        end

        it "handles attacked_stop event" do
          @c.should_receive(:handle).with(:attacked_stop)
          @c.check_proximity
        end

        context "already handling attacked_stop" do
          it "does not register another attacked_stop handler"
        end

        it "attacks ship" do
          @c.should_receive(:attack).with{ |*a| a[0].id.should == @o.id }
          @c.check_proximity
        end

        context "attacked_stop" do
          it "resumes patrol route" do
            @c.should_receive :patrol_route
            @c.check_proximity
            @c.raise_event :attacked_stop
          end
        end
      end
    end
  end # describe Corvette
end # module Omega::Client
